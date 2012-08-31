#include "AudioThruEngine.h"
#include "AudioRingBuffer.h"
#include "CARingBuffer.h"
#include <unistd.h>

#define USE_AUDIODEVICEREAD 0
#if USE_AUDIODEVICEREAD
AudioBufferList *gInputIOBuffer = NULL;
#endif

#define kSecondsInRingBuffer 2.

AudioThruEngine::AudioThruEngine() :
  mWorkBuf(NULL),
  mRunning(false),
  mMuting(false),
  mThruing(true),
  mBufferSize(512),
  mExtraLatencyFrames(0)
{
//  mInputBuffer = new CARingBuffer();
  mInputBuffer = new AudioRingBuffer(4, 88200);
}

AudioThruEngine::~AudioThruEngine()
{
  Stop();
  InitInputDevice(kAudioDeviceUnknown);
  InitOutputDevice(kAudioDeviceUnknown);
  delete mInputBuffer;
}

void  AudioThruEngine::InitInputDevice(AudioDeviceID input)
{
  mInputDevice.Init(input, true);
  SetBufferSize(mBufferSize);

    SetChannelMap(0, 0);
    SetChannelMap(1, 1);

//  mInputBuffer = new CARingBuffer();
//  mInputBuffer->Allocate(2, 4, 88200);
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

  mInputBuffer->Allocate(mInputDevice.mFormat.mBytesPerFrame, UInt32(kSecondsInRingBuffer * mInputDevice.mFormat.mSampleRate));

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

void  AudioThruEngine::ComputeThruOffset()
{
  if (!mRunning) {
    mActualThruLatency = 0;
    mInToOutSampleOffset = 0;
    return;
  }

  mActualThruLatency = SInt32(mInputDevice.mSafetyOffset + /*2 * */ mInputDevice.mBufferSizeFrames +
            mOutputDeviceID.mSafetyOffset + mOutputDeviceID.mBufferSizeFrames) + mExtraLatencyFrames;
  mInToOutSampleOffset = mActualThruLatency + mIODeltaSampleCount;
}

bool  AudioThruEngine::Stop()
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
  
  UInt64 nFrames = This->mInputDevice.mBufferSizeFrames;
  UInt64 startFrame =UInt64(inInputTime->mSampleTime);
  
  This->mInputBuffer->Store((const Byte *)inInputData->mBuffers[0].mData, nFrames, startFrame);

  return noErr;
}

inline void MakeBufferSilent(AudioBufferList * ioData)
{
	for(UInt32 i=0; i<ioData->mNumberBuffers;i++)
		memset(ioData->mBuffers[i].mData, 0, ioData->mBuffers[i].mDataByteSize);
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
    UInt64 nFrames = This->mInputDevice.mBufferSizeFrames;
    UInt64 startFrame = inOutputTime->mSampleTime - This->mInToOutSampleOffset;

    double delta = This->mInputBuffer->Fetch(This->mWorkBuf, nFrames, startFrame);

    UInt32 innchnls = This->mInputDevice.mFormat.mChannelsPerFrame;
    UInt32* chanstart = new UInt32[64];

    for (UInt32 buf = 0; buf < outOutputData->mNumberBuffers; buf++)
    {
      for (int i = 0; i < 64; i++)
        chanstart[i] = 0;
      UInt32 outnchnls = outOutputData->mBuffers[buf].mNumberChannels;
      for (UInt32 chan = 0; chan < innchnls; chan++)
      {
        UInt32 outChan = This->GetChannelMap(chan) - chanstart[chan];
//        if (outChan >= 0 && outChan < outnchnls) // removed, compiler warning
        if (outChan < outnchnls)
        {
          float *in = (float *)This->mWorkBuf + (chan % innchnls);
          float *out = (float *)outOutputData->mBuffers[buf].mData + outChan;
          long framesize = outnchnls * sizeof(float);

          for (UInt32 frame = 0; frame < outOutputData->mBuffers[buf].mDataByteSize; frame += framesize )
          {
            *out += *in;
            in += innchnls;
            out += outnchnls;
          }
        }
        chanstart[chan] += outnchnls;
      }
    }

    delete [] chanstart;
    This->mThruTime = delta;
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
