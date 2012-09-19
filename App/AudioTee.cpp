#include <iostream>
#include <fstream>
#include <time.h>
#include <AudioToolbox/AudioFile.h>
#include <AudioToolbox/AudioConverter.h>
#include <CARingBuffer.h>
#include <CABitOperations.h>
#include "AudioTee.h"
#include "AudioDevice.h"
#include "WavFileUtils.h"

AudioTee::AudioTee(AudioDeviceID inputDeviceID, AudioDeviceID outputDeviceID) : mWorkBuf(NULL), mSecondsInHistoryBuffer(20), mHistBuf(), mHistoryBufferMaxByteSize(0), mBufferSize(1024), mInputDevice(inputDeviceID, true), mOutputDevice(outputDeviceID, false), mFirstRun(true), mRunning(false), mMuting(false), mThruing(true), mHistoryBufferByteSize(0), mHistoryBufferHeadOffsetFrameNumber(0) {
  mInputDevice.SetBufferSize(mBufferSize);
  mOutputDevice.SetBufferSize(mBufferSize);
}

void AudioTee::Start() {
  if (mRunning) return;
  if (mInputDevice.mID == kAudioDeviceUnknown || mOutputDevice.mID == kAudioDeviceUnknown) return;
  if (mInputDevice.mFormat.mSampleRate != mOutputDevice.mFormat.mSampleRate) {
    printf("Error in AudioTee::Start() - sample rate mismatch: %f / %f\n", mInputDevice.mFormat.mSampleRate, mOutputDevice.mFormat.mSampleRate);
    return;
  }
  mSampleRate = mInputDevice.mFormat.mSampleRate;
  mWorkBuf = new Byte[mInputDevice.mBufferSizeFrames * mInputDevice.mFormat.mBytesPerFrame];
  memset(mWorkBuf, 0, mInputDevice.mBufferSizeFrames * mInputDevice.mFormat.mBytesPerFrame);
  UInt32 framesInHistoryBuffer = NextPowerOfTwo(mInputDevice.mFormat.mSampleRate * mSecondsInHistoryBuffer);
  mHistoryBufferMaxByteSize = mInputDevice.mFormat.mBytesPerFrame * framesInHistoryBuffer;
  mHistBuf = new CARingBuffer();
  mHistBuf->Allocate(2, mInputDevice.mFormat.mBytesPerFrame, framesInHistoryBuffer);
  printf("Initializing history buffer with byte capacity %u — %f seconds at %f kHz", mHistoryBufferMaxByteSize, (mHistoryBufferMaxByteSize / mInputDevice.mFormat.mSampleRate / (4 * 2)), mInputDevice.mFormat.mSampleRate);
  printf("Initializing work buffer with mBufferSizeFrames:%u and mBytesPerFrame %u\n", mInputDevice.mBufferSizeFrames, mInputDevice.mFormat.mBytesPerFrame);
  mRunning = true;
  mInputIOProcID = NULL;
  AudioDeviceCreateIOProcID(mInputDevice.mID, InputIOProc, this, &mInputIOProcID);
  AudioDeviceStart(mInputDevice.mID, mInputIOProcID);
  mOutputIOProc = OutputIOProc;
  mOutputIOProcID = NULL;
  AudioDeviceCreateIOProcID(mOutputDevice.mID, mOutputIOProc, this, &mOutputIOProcID);
  AudioDeviceStart(mOutputDevice.mID, mOutputIOProcID);
}

bool AudioTee::Stop() {
  if (!mRunning) return false;
  mRunning = false;
  usleep(5000);
  AudioDeviceStop(mInputDevice.mID, mInputIOProcID);
  AudioDeviceDestroyIOProcID(mInputDevice.mID, mInputIOProcID);
  AudioDeviceStop(mOutputDevice.mID, mOutputIOProcID);
  AudioDeviceDestroyIOProcID(mOutputDevice.mID, mOutputIOProcID);
  if (mWorkBuf) {
    delete[] mWorkBuf;
    mWorkBuf = NULL;
  }
  return true;
}

OSStatus AudioTee::InputIOProc(AudioDeviceID inDevice, const AudioTimeStamp *inNow, const AudioBufferList *inInputData, const AudioTimeStamp *inInputTime, AudioBufferList *outOutputData, const AudioTimeStamp *inOutputTime, void *inClientData) {
  AudioTee *This = (AudioTee *)inClientData;
  for(UInt32 i=0; i<outOutputData->mNumberBuffers; i++){
    memcpy(This->mWorkBuf, inInputData->mBuffers[i].mData, inInputData->mBuffers[i].mDataByteSize);
    AudioBuffer ab;
    AudioBufferList abl;
    ab.mDataByteSize = inInputData->mBuffers[i].mDataByteSize;
    ab.mData = This->mWorkBuf;
    abl.mBuffers[0] = ab;
    abl.mNumberBuffers = 1;
    This->mHistBuf->Store(&abl, (inInputData->mBuffers[i].mDataByteSize / inInputData->mBuffers[i].mNumberChannels) / sizeof(UInt32), This->mHistoryBufferHeadOffsetFrameNumber);
    if(This->mHistoryBufferByteSize < (This->mHistoryBufferMaxByteSize - inInputData->mBuffers[i].mDataByteSize)){
      This->mHistoryBufferByteSize += inInputData->mBuffers[i].mDataByteSize;
    } else {
      This->mHistoryBufferByteSize = This->mHistoryBufferMaxByteSize;
    }
    This->mHistoryBufferHeadOffsetFrameNumber = ((This->mHistoryBufferHeadOffsetFrameNumber + (inInputData->mBuffers[i].mDataByteSize / 8)) % (This->mHistoryBufferMaxByteSize / 8));
  }
  return noErr;
}

OSStatus AudioTee::OutputIOProc(AudioDeviceID inDevice, const AudioTimeStamp *inNow, const AudioBufferList *inInputData, const AudioTimeStamp *inInputTime, AudioBufferList *outOutputData, const AudioTimeStamp *inOutputTime, void *inClientData) {
  AudioTee *This = (AudioTee *)inClientData;
  if (!This->mMuting && This->mThruing) {
    for(UInt32 i=0; i<outOutputData->mNumberBuffers; i++){
      UInt32 bytesToCopy = outOutputData->mBuffers[i].mDataByteSize;
      memcpy(outOutputData->mBuffers[i].mData, This->mWorkBuf, bytesToCopy);
    }
  }
  return noErr;
}

void AudioTee::saveHistoryBuffer(const char* fileName, UInt32 secondsRequested){
  UInt32 numberOfBytesWeWant = secondsRequested * mInputDevice.mFormat.mSampleRate * (4 * 2);
  int32_t numberOfBytesToRequest = std::min(numberOfBytesWeWant, mHistoryBufferByteSize);
  AudioBuffer *buffer = new AudioBuffer();
  buffer->mDataByteSize = numberOfBytesToRequest;
  buffer->mData = new UInt32[buffer->mDataByteSize];
  AudioBufferList *abl = new AudioBufferList();
  abl->mNumberBuffers = 1;
  abl->mBuffers[0] = *buffer;
  numberOfBytesToRequest = buffer->mDataByteSize;
  UInt32 nFrames = numberOfBytesToRequest / (4 * 2);
  mHistBuf->Fetch(abl, nFrames, mHistoryBufferHeadOffsetFrameNumber);
  WavFileUtils::writeWavFileHeaders(fileName, numberOfBytesToRequest, mOutputDevice.mFormat.mSampleRate, 16);
  WavFileUtils::writeBytesToFile(fileName, (UInt32*)abl->mBuffers[0].mData, numberOfBytesToRequest, nFrames, this->mOutputDevice.mFormat);
  delete buffer;
  delete abl;
}
