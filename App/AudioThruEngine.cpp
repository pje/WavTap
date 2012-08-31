#include "AudioThruEngine.h"
#include <unistd.h>

AudioThruEngine::AudioThruEngine() :
  mWorkBuf(NULL),
  mRunning(false),
  mMuting(false),
  mThruing(true),
  mBufferSize(1024),
  mExtraLatencyFrames(0)
{
}

AudioThruEngine::~AudioThruEngine()
{
  Stop();
  InitInputDevice(kAudioDeviceUnknown);
  InitOutputDevice(kAudioDeviceUnknown);
}

void  AudioThruEngine::InitInputDevice(AudioDeviceID input)
{
  mInputDevice.Init(input, true);
  SetBufferSize(mBufferSize);
}

void  AudioThruEngine::InitOutputDevice(AudioDeviceID output)
{
  mOutputDeviceID.Init(output, false);
  SetBufferSize(mBufferSize);
}

void  AudioThruEngine::SetBufferSize(UInt32 size)
{
  bool wasRunning = Stop();
  mBufferSize = size;
  mInputDevice.SetBufferSize(size);
  mOutputDeviceID.SetBufferSize(size);
  if (wasRunning) Start();
}

void  AudioThruEngine::ComputeThruOffset()
{
  if (!mRunning) {
    mActualThruLatency = 0;
    mInToOutSampleOffset = 0;
    return;
  }

  mActualThruLatency = SInt32(mInputDevice.mSafetyOffset + mInputDevice.mBufferSizeFrames + mOutputDeviceID.mSafetyOffset + mOutputDeviceID.mBufferSizeFrames) + mExtraLatencyFrames;
  mInToOutSampleOffset = mActualThruLatency + mIODeltaSampleCount;
}

OSStatus AudioThruEngine::MatchSampleRate(bool useInputDevice)
{
  OSStatus status = kAudioHardwareNoError;
  mInputDevice.UpdateFormat();
  mOutputDeviceID.UpdateFormat();
  if (mInputDevice.mFormat.mSampleRate != mOutputDeviceID.mFormat.mSampleRate)
  {
    if (useInputDevice) {
      status = mOutputDeviceID.SetSampleRate(mInputDevice.mFormat.mSampleRate);
    } else {
      status = mInputDevice.SetSampleRate(mOutputDeviceID.mFormat.mSampleRate);
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

void AudioThruEngine::Start()
{
  OSStatus err = noErr;
  if (mRunning) return;
  if (!mInputDevice.Valid() || !mOutputDeviceID.Valid()) return;

  if (mInputDevice.mFormat.mSampleRate != mOutputDeviceID.mFormat.mSampleRate) {
    if (MatchSampleRate(false)) {
      printf("Error - sample rate mismatch: %f / %f\n", mInputDevice.mFormat.mSampleRate, mOutputDeviceID.mFormat.mSampleRate);
      return;
    }
  }

  mSampleRate = mInputDevice.mFormat.mSampleRate;

  mWorkBuf = new Byte[mInputDevice.mBufferSizeFrames * mInputDevice.mFormat.mBytesPerFrame];
  memset(mWorkBuf, 0, mInputDevice.mBufferSizeFrames * mInputDevice.mFormat.mBytesPerFrame);

  mRunning = true;

  mInputProcState = kStarting;
  mOutputProcState = kStarting;

  mInputIOProcID = NULL;
  err = AudioDeviceCreateIOProcID(mInputDevice.mID, InputIOProc, this, &mInputIOProcID);
  err = AudioDeviceStart(mInputDevice.mID, mInputIOProcID);

  mOutputIOProc = OutputIOProc;

  mOutputIOProcID = NULL;
  err = AudioDeviceCreateIOProcID(mOutputDeviceID.mID, mOutputIOProc, this, &mOutputIOProcID);
  err = AudioDeviceStart(mOutputDeviceID.mID, mOutputIOProcID);

  while (mInputProcState != kRunning || mOutputProcState != kRunning) {
    usleep(1000);
  }

  ComputeThruOffset();
}

bool AudioThruEngine::Stop()
{
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

  err = AudioDeviceStop(mOutputDeviceID.mID, mOutputIOProcID);
  err = AudioDeviceDestroyIOProcID(mOutputDeviceID.mID, mOutputIOProcID);

  if (mWorkBuf) {
    delete[] mWorkBuf;
    mWorkBuf = NULL;
  }

  return true;
}

OSStatus AudioThruEngine::InputIOProc(AudioDeviceID inDevice,
                                      const AudioTimeStamp *inNow,
                                      const AudioBufferList *inInputData,
                                      const AudioTimeStamp *inInputTime,
                                      AudioBufferList *outOutputData,
                                      const AudioTimeStamp *inOutputTime,
                                      void *inClientData)
{
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

OSStatus AudioThruEngine::OutputIOProc(AudioDeviceID inDevice,
                                       const AudioTimeStamp *inNow,
                                       const AudioBufferList *inInputData,
                                       const AudioTimeStamp *inInputTime,
                                       AudioBufferList *outOutputData,
                                       const AudioTimeStamp *inOutputTime,
                                       void *inClientData)
{
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

UInt32 AudioThruEngine::GetOutputNchnls()
{
  if (mOutputDeviceID.mID != kAudioDeviceUnknown) {
    return mOutputDeviceID.CountChannels();
  }
  return 0;
}
