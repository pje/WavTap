#include "AudioThruEngine.h"
#include "AudioDevice.h"
#include <unistd.h>

AudioThruEngine::AudioThruEngine(AudioDeviceID inputDeviceID, AudioDeviceID outputDeviceID) : mWorkBuf(NULL), mBufferSize(512), mExtraLatencyFrames(0), mInputDevice(inputDeviceID, true), mOutputDevice(outputDeviceID, false), mRunning(false), mMuting(false), mThruing(true) {
  mInputDevice.SetBufferSize(mBufferSize);
  mOutputDevice.SetBufferSize(mBufferSize);
}

void  AudioThruEngine::ComputeThruOffset() {
  if (!mRunning) {
    mActualThruLatency = 0;
    mInToOutSampleOffset = 0;
    return;
  }

  mActualThruLatency = SInt32(mInputDevice.mSafetyOffset + mInputDevice.mBufferSizeFrames + mOutputDevice.mSafetyOffset + mOutputDevice.mBufferSizeFrames) + mExtraLatencyFrames;
  mInToOutSampleOffset = mActualThruLatency + mIODeltaSampleCount;
}

OSStatus AudioThruEngine::MatchSampleRates(AudioObjectID changedDeviceID) {
  OSStatus status = kAudioHardwareNoError;
  mInputDevice.ReloadStreamFormat();
  mOutputDevice.ReloadStreamFormat();
  if (mInputDevice.mFormat.mSampleRate != mOutputDevice.mFormat.mSampleRate)
  {
    if (mInputDevice.mID == changedDeviceID) {
      status = mOutputDevice.SetSampleRate(mInputDevice.mFormat.mSampleRate);
    } else if (mOutputDevice.mID == changedDeviceID) {
      status = mInputDevice.SetSampleRate(mOutputDevice.mFormat.mSampleRate);
    }
    else {
      printf("Error in AudioThruEngine::MatchSampleRates() - unrelated device ID: %u \n", changedDeviceID);
    }
  }

  return status;
}

inline void MakeBufferSilent(AudioBufferList * ioData)
{
	for(UInt32 i=0; i<ioData->mNumberBuffers; i++){
		memset(ioData->mBuffers[i].mData, 0, ioData->mBuffers[i].mDataByteSize);
  }
}

void AudioThruEngine::Start() {
  OSStatus err = noErr;
  if (mRunning) return;
  if (!mInputDevice.Valid() || !mOutputDevice.Valid()) return;

  MatchSampleRates(mOutputDevice.mID);

  if (mInputDevice.mFormat.mSampleRate != mOutputDevice.mFormat.mSampleRate) {
    printf("Error in AudioThruEngine::Start() - sample rate mismatch: %f / %f\n", mInputDevice.mFormat.mSampleRate, mOutputDevice.mFormat.mSampleRate);
    return;
  }

  mSampleRate = mInputDevice.mFormat.mSampleRate;

  mWorkBuf = new Byte[mInputDevice.mBufferSizeFrames * mInputDevice.mFormat.mBytesPerFrame];
  memset(mWorkBuf, 0, mInputDevice.mBufferSizeFrames * mInputDevice.mFormat.mBytesPerFrame);

  printf("Initializing mWorkBuf with mBufferSizeFrames:%u and mBytesPerFrame %u\n", mInputDevice.mBufferSizeFrames, mInputDevice.mFormat.mBytesPerFrame);

  mRunning = true;

  mInputProcState = kStarting;
  mOutputProcState = kStarting;

  mInputIOProcID = NULL;
  err = AudioDeviceCreateIOProcID(mInputDevice.mID, InputIOProc, this, &mInputIOProcID);
  err = AudioDeviceStart(mInputDevice.mID, mInputIOProcID);

  mOutputIOProc = OutputIOProc;

  mOutputIOProcID = NULL;
  err = AudioDeviceCreateIOProcID(mOutputDevice.mID, mOutputIOProc, this, &mOutputIOProcID);
  err = AudioDeviceStart(mOutputDevice.mID, mOutputIOProcID);

  while (mInputProcState != kRunning || mOutputProcState != kRunning) {
    usleep(1000);
  }

  ComputeThruOffset();
}

bool AudioThruEngine::Stop() {
  OSStatus err = noErr;
  if (!mRunning) return false;
  mRunning = false;

  mInputProcState = kStopRequested;
  mOutputProcState = kStopRequested;

  while (mInputProcState != kOff || mOutputProcState != kOff){
    usleep(5000);
  }

  err = AudioDeviceStop(mInputDevice.mID, mInputIOProcID);
  err = AudioDeviceDestroyIOProcID(mInputDevice.mID, mInputIOProcID);

  err = AudioDeviceStop(mOutputDevice.mID, mOutputIOProcID);
  err = AudioDeviceDestroyIOProcID(mOutputDevice.mID, mOutputIOProcID);

  if (mWorkBuf) {
    delete[] mWorkBuf;
    mWorkBuf = NULL;
  }

  return true;
}

OSStatus AudioThruEngine::InputIOProc(AudioDeviceID inDevice, const AudioTimeStamp *inNow, const AudioBufferList *inInputData, const AudioTimeStamp *inInputTime, AudioBufferList *outOutputData, const AudioTimeStamp *inOutputTime, void *inClientData) {
  AudioThruEngine *This = (AudioThruEngine *)inClientData;

  switch (This->mInputProcState) {
  case kStarting:
    This->mInputProcState = kRunning;
    break;
  case kStopRequested:
    AudioDeviceStop(inDevice, InputIOProc);
    This->mInputProcState = kOff;
    return noErr;
  default:
    break;
  }

  This->mLastInputSampleCount = inInputTime->mSampleTime;

  for(UInt32 i=0; i<outOutputData->mNumberBuffers; i++){
    memcpy(This->mWorkBuf, inInputData->mBuffers[i].mData, inInputData->mBuffers[i].mDataByteSize);
  }

  return noErr;
}

OSStatus AudioThruEngine::OutputIOProc(AudioDeviceID inDevice, const AudioTimeStamp *inNow, const AudioBufferList *inInputData, const AudioTimeStamp *inInputTime, AudioBufferList *outOutputData, const AudioTimeStamp *inOutputTime, void *inClientData) {
  AudioThruEngine *This = (AudioThruEngine *)inClientData;

  switch (This->mOutputProcState) {
  case kStarting:
    if (This->mInputProcState == kRunning) {
      This->mOutputProcState = kRunning;
      This->mIODeltaSampleCount = inOutputTime->mSampleTime - This->mLastInputSampleCount;
    }
    return noErr;
  case kStopRequested:
    AudioDeviceStop(inDevice, This->mOutputIOProc);
    This->mOutputProcState = kOff;
    return noErr;
  default:
    break;
  }

  if (!This->mMuting && This->mThruing) {
    for(UInt32 i=0; i<outOutputData->mNumberBuffers; i++){
      memcpy(outOutputData->mBuffers[i].mData, This->mWorkBuf, outOutputData->mBuffers[i].mDataByteSize);
    }
  } else {
    This->mThruTime = 0.;
  }
  return noErr;
}

UInt32 AudioThruEngine::GetOutputNchnls() {
  if (mOutputDevice.mID != kAudioDeviceUnknown) {
    return mOutputDevice.CountChannels();
  }
  return 0;
}
