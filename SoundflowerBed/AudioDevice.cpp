#include "AudioDevice.h"

void  AudioDevice::Init(AudioDeviceID devid, bool isInput)
{
  mID = devid;
  mIsInput = isInput;
  if (mID == kAudioDeviceUnknown) return;

  UInt32 propsize;

  propsize = sizeof(UInt32);
  verify_noerr(AudioDeviceGetProperty(mID, 0, mIsInput, kAudioDevicePropertySafetyOffset, &propsize, &mSafetyOffset));

  propsize = sizeof(UInt32);
  verify_noerr(AudioDeviceGetProperty(mID, 0, mIsInput, kAudioDevicePropertyBufferFrameSize, &propsize, &mBufferSizeFrames));

  UpdateFormat();
}

void  AudioDevice::UpdateFormat()
{
  UInt32 propsize = sizeof(AudioStreamBasicDescription);
  verify_noerr(AudioDeviceGetProperty(mID, 0, mIsInput, kAudioDevicePropertyStreamFormat, &propsize, &mFormat));
}

void  AudioDevice::SetBufferSize(UInt32 size)
{
  UInt32 propsize = sizeof(UInt32);
  verify_noerr(AudioDeviceSetProperty(mID, NULL, 0, mIsInput, kAudioDevicePropertyBufferFrameSize, propsize, &size));

  propsize = sizeof(UInt32);
  verify_noerr(AudioDeviceGetProperty(mID, 0, mIsInput, kAudioDevicePropertyBufferFrameSize, &propsize, &mBufferSizeFrames));
}

OSStatus  AudioDevice::SetSampleRate(Float64 sr)
{
  UInt32 propsize = sizeof(AudioStreamBasicDescription);
  mFormat.mSampleRate = sr;
  OSStatus err = AudioDeviceSetProperty(mID, NULL, 0, mIsInput, kAudioDevicePropertyStreamFormat, propsize, &mFormat);

  // now re-read to see what actual value is
  UpdateFormat();

  return err;
}


int    AudioDevice::CountChannels()
{
  OSStatus err;
  UInt32 propSize;
  int result = 0;

  err = AudioDeviceGetPropertyInfo(mID, 0, mIsInput, kAudioDevicePropertyStreamConfiguration, &propSize, NULL);
  if (err) return 0;

  AudioBufferList *buflist = (AudioBufferList *)malloc(propSize);
  err = AudioDeviceGetProperty(mID, 0, mIsInput, kAudioDevicePropertyStreamConfiguration, &propSize, buflist);
  if (!err) {
    for (UInt32 i = 0; i < buflist->mNumberBuffers; ++i) {
      result += buflist->mBuffers[i].mNumberChannels;
    }
  }
  free(buflist);
  return result;
}

char *  AudioDevice::GetName(char *buf, UInt32 maxlen)
{
  verify_noerr(AudioDeviceGetProperty(mID, 0, mIsInput, kAudioDevicePropertyDeviceName, &maxlen, buf));
  return buf;
}
