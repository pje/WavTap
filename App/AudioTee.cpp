#include <iostream>
#include <fstream>
#include <time.h>
#include <AudioToolbox/AudioFile.h>
#include <AudioToolbox/AudioConverter.h>
#include <CARingBuffer.h>
#include <CABitOperations.h>
#include "AudioTee.hpp"
#include "AudioDevice.hpp"
#include "WavFileUtils.hpp"

AudioTee::AudioTee(AudioDeviceID inputDeviceID, AudioDeviceID outputDeviceID) : mInputDevice(inputDeviceID, true), mOutputDevice(outputDeviceID, false), mSecondsInHistoryBuffer(20), mWorkBuf(NULL), mHistBuf(), mHistoryBufferMaxByteSize(0), mBufferSize(128), mHistoryBufferByteSize(0), mHistoryBufferHeadOffsetFrameNumber(0) {
  syslog(LOG_NOTICE, "%s: Initializing AudioTee buffers with mBufferSize:%u", __func__, mBufferSize);
  AudioObjectShow(inputDeviceID);
  AudioObjectShow(outputDeviceID);
  mInputDevice.SetBufferSize(mBufferSize);
  mOutputDevice.SetBufferSize(mBufferSize);
}

// In audio data a frame is one sample across all channels. In non-interleaved
// audio, the per frame fields identify one channel. In interleaved audio, the per
// frame fields identify the set of n channels. In uncompressed audio, a Packet is
// one frame, (mFramesPerPacket == 1)
void AudioTee::start() {
  if (mInputDevice.mID == kAudioDeviceUnknown || mOutputDevice.mID == kAudioDeviceUnknown) return;
  if (mInputDevice.mFormat.mSampleRate != mOutputDevice.mFormat.mSampleRate) {
    syslog(LOG_ERR, "%s: sample rate mismatch: %f / %f", __func__, mInputDevice.mFormat.mSampleRate, mOutputDevice.mFormat.mSampleRate);
    return;
  }
  mWorkBuf = new Byte[mInputDevice.mBufferSizeFrames * mInputDevice.mFormat.mBytesPerFrame];
  UInt32 framesInHistoryBuffer = NextPowerOfTwo(mInputDevice.mFormat.mSampleRate * mSecondsInHistoryBuffer);
  mHistoryBufferMaxByteSize = mInputDevice.mFormat.mBytesPerFrame * framesInHistoryBuffer;
  mHistBuf = new CARingBuffer();
  mHistBuf->Allocate(2, mInputDevice.mFormat.mBytesPerFrame, framesInHistoryBuffer);
  syslog(LOG_NOTICE, "%s: Initializing work buffer with mBufferSizeFrames:%u and mBytesPerFrame %u\n", __func__, mInputDevice.mBufferSizeFrames, mInputDevice.mFormat.mBytesPerFrame);
  mInputIOProcID = NULL;
  AudioDeviceCreateIOProcID(mInputDevice.mID, InputIOProc, this, &mInputIOProcID);
  AudioDeviceStart(mInputDevice.mID, mInputIOProcID);
  mOutputIOProc = OutputIOProc;
  mOutputIOProcID = NULL;
  AudioDeviceCreateIOProcID(mOutputDevice.mID, mOutputIOProc, this, &mOutputIOProcID);
  AudioDeviceStart(mOutputDevice.mID, mOutputIOProcID);
}

void AudioTee::stop() {
  AudioDeviceStop(mInputDevice.mID, mInputIOProcID);
  AudioDeviceDestroyIOProcID(mInputDevice.mID, mInputIOProcID);
  AudioDeviceStop(mOutputDevice.mID, mOutputIOProcID);
  AudioDeviceDestroyIOProcID(mOutputDevice.mID, mOutputIOProcID);
  if (mWorkBuf) {
    delete[] mWorkBuf;
    mWorkBuf = NULL;
  }
}

OSStatus AudioTee::InputIOProc(AudioDeviceID inDevice, const AudioTimeStamp *inNow, const AudioBufferList *inInputData, const AudioTimeStamp *inInputTime, AudioBufferList *outOutputData, const AudioTimeStamp *inOutputTime, void *inClientData) {
  AudioTee *This = (AudioTee *)inClientData;
  for(UInt32 i = 0; i < outOutputData->mNumberBuffers; i++) {
//    syslog(LOG_NOTICE, "%s: inInputTime : %u, inNow: %u, inOutputTime: %u\n", __func__, (UInt32)inInputTime->mSampleTime, (UInt32)inNow->mSampleTime, (UInt32)inOutputTime->mSampleTime);
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
    UInt32 frameSize = sizeof(UInt32) * inInputData->mBuffers[i].mNumberChannels;
    This->mHistoryBufferHeadOffsetFrameNumber = ((This->mHistoryBufferHeadOffsetFrameNumber + (inInputData->mBuffers[i].mDataByteSize / frameSize)) % (This->mHistoryBufferMaxByteSize / frameSize));
  }
  return noErr;
}

OSStatus AudioTee::OutputIOProc(AudioDeviceID inDevice, const AudioTimeStamp *inNow, const AudioBufferList *inInputData, const AudioTimeStamp *inInputTime, AudioBufferList *outOutputData, const AudioTimeStamp *inOutputTime, void *inClientData) {
  AudioTee *This = (AudioTee *)inClientData;
//  syslog(LOG_NOTICE, "%s: inInputTime: %u, inNow: %u, inOutputTime: %u\n", __func__, (UInt32)inInputTime->mSampleTime, (UInt32)inNow->mSampleTime, (UInt32)inOutputTime->mSampleTime);

  for(UInt32 i = 0; i < outOutputData->mNumberBuffers; i++) {
    memcpy(outOutputData->mBuffers[i].mData, This->mWorkBuf, outOutputData->mBuffers[i].mDataByteSize);
  }

//  This->mHistBuf->Fetch(outOutputData, outOutputData->mBuffers[0].mDataByteSize, This->mHistoryBufferHeadOffsetFrameNumber);

  return noErr;
}

void AudioTee::saveHistoryBuffer(const char* fileName, UInt32 secondsRequested){
  UInt32 frameSize = sizeof(UInt32) * 2;
  UInt32 numberOfBytesWeWant = secondsRequested * mInputDevice.mFormat.mSampleRate * frameSize;
  int32_t numberOfBytesToRequest = std::min(numberOfBytesWeWant, mHistoryBufferByteSize);
  AudioBuffer *buffer = new AudioBuffer();
  buffer->mDataByteSize = numberOfBytesToRequest;
  buffer->mData = new UInt32[buffer->mDataByteSize];
  AudioBufferList *abl = new AudioBufferList();
  abl->mNumberBuffers = 1;
  abl->mBuffers[0] = *buffer;
  numberOfBytesToRequest = buffer->mDataByteSize;
  UInt32 nFrames = numberOfBytesToRequest / frameSize;
  mHistBuf->Fetch(abl, nFrames, mHistoryBufferHeadOffsetFrameNumber);
  WavFileUtils::writeWavFileHeaders(fileName, numberOfBytesToRequest, mOutputDevice.mFormat.mSampleRate, 16);
  WavFileUtils::writeBytesToFile(fileName, (UInt32*)abl->mBuffers[0].mData, numberOfBytesToRequest, nFrames, this->mOutputDevice.mFormat);
  delete buffer;
  delete abl;
}
