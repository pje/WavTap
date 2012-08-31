#include "AudioDevice.h"

void AudioDevice::UpdateFormat()
{
  OSStatus err = noErr;
  UInt32 size = sizeof(mFormat);

  AudioObjectPropertyAddress theAddress = {
    kAudioDevicePropertyStreamFormat,
    (mIsInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput),
    0
  };

  err = AudioObjectGetPropertyData(mID, &theAddress, 0, NULL, &size, &mFormat);
}

OSStatus AudioDevice::SetSampleRate(Float64 sr)
{
  OSStatus err = noErr;
  mFormat.mSampleRate = sr;
  UInt32 size = sizeof(AudioStreamBasicDescription);

  AudioObjectPropertyAddress theAddress = {
    kAudioDevicePropertyStreamFormat,
    (mIsInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput),
    0
  };

  err = AudioObjectSetPropertyData(mID, &theAddress, 0, NULL, size, &size);

  UpdateFormat();
  return err;
}

void AudioDevice::Init(AudioDeviceID devid, bool isInput)
{
	OSStatus err = noErr;
	mID = devid;
	mIsInput = isInput;
	if (mID == kAudioDeviceUnknown) return;
  UInt32 size = sizeof(Float32);

  AudioObjectPropertyAddress theAddress = {
    kAudioDevicePropertySafetyOffset,
    (mIsInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput),
    0
  };
  err = AudioObjectGetPropertyData(mID, &theAddress, 0, NULL, &size, &mSafetyOffset);

	size = sizeof(UInt32);
  theAddress.mSelector = kAudioDevicePropertyBufferFrameSize;
  err = AudioObjectGetPropertyData(mID, &theAddress, 0, NULL, &size, &mBufferSizeFrames);

	size = sizeof(AudioStreamBasicDescription);
  theAddress.mSelector = kAudioDevicePropertyStreamFormat;
  err = AudioObjectGetPropertyData(mID, &theAddress, 0, NULL, &size, &mFormat);
}

void AudioDevice::SetBufferSize(UInt32 buffersize)
{
	OSStatus err = noErr;
  UInt32 size = sizeof(UInt32);

  AudioObjectPropertyAddress theAddress = {
    kAudioDevicePropertyBufferFrameSize,
    (mIsInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput),
    0
  };

  err = AudioObjectSetPropertyData(mID, &theAddress, 0, NULL, size, &buffersize);
  err = AudioObjectGetPropertyData(mID, &theAddress, 0, NULL, &size, &mBufferSizeFrames);
}

int AudioDevice::CountChannels()
{
	OSStatus err = noErr;
	UInt32 size; // TODO: wat?
	int result = 0;

  AudioObjectPropertyAddress theAddress = {
    kAudioDevicePropertyStreamConfiguration,
    (mIsInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput),
    0
  };

  err = AudioObjectGetPropertyDataSize(mID, &theAddress, 0, NULL, &size);
	if (err) return 0;

	AudioBufferList *buflist = (AudioBufferList *)malloc(size);
  err = AudioObjectGetPropertyData(mID, &theAddress, 0, NULL, &size, buflist);
	if (!err) {
		for (UInt32 i = 0; i < buflist->mNumberBuffers; ++i) {
			result += buflist->mBuffers[i].mNumberChannels;
		}
	}
	free(buflist);
	return result;
}

char *	AudioDevice::GetName(char *buf, UInt32 maxlen)
{
	OSStatus err = noErr;

  AudioObjectPropertyAddress theAddress = {
    kAudioDevicePropertyDeviceName,
    (mIsInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput),
    0
  };

  err = AudioObjectGetPropertyData(mID, &theAddress, 0, NULL,  &maxlen, buf);

	return buf;
}
