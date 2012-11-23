#include "AudioDevice.hpp"

AudioDevice::AudioDevice(AudioDeviceID id, bool isInput) {
	mID = id;
	mIsInput = isInput;
	if (mID == kAudioDeviceUnknown) return;
  UInt32 size = sizeof(Float32);
  AudioObjectPropertyAddress addr = { kAudioDevicePropertySafetyOffset, (mIsInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput), 0 };
  AudioObjectGetPropertyData(mID, &addr, 0, NULL, &size, &mSafetyOffset);
	size = sizeof(UInt32);
  addr.mSelector = kAudioDevicePropertyBufferFrameSize;
  AudioObjectGetPropertyData(mID, &addr, 0, NULL, &size, &mBufferSizeFrames);
	size = sizeof(AudioStreamBasicDescription);
  addr.mSelector = kAudioDevicePropertyStreamFormat;
  AudioObjectGetPropertyData(mID, &addr, 0, NULL, &size, &mFormat);
}

OSStatus AudioDevice::ReloadStreamFormat() {
  OSStatus err = noErr;
  UInt32 size = sizeof(mFormat);
  AudioObjectPropertyAddress addr = { kAudioDevicePropertyStreamFormat, (mIsInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput), 0 };
  err = AudioObjectGetPropertyData(mID, &addr, 0, NULL, &size, &mFormat);
  return err;
}

OSStatus AudioDevice::SetSampleRate(Float64 sr) {
  OSStatus err = noErr;
  mFormat.mSampleRate = sr;
  UInt32 size = sizeof(mFormat);
  AudioObjectPropertyAddress addr = { kAudioDevicePropertyStreamFormat, (mIsInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput), 0 };
  err = AudioObjectSetPropertyData(mID, &addr, 0, NULL, size, &mFormat);
  if(mFormat.mSampleRate != sr) printf("Error in AudioDevice::SetSampleRate - sample rate mismatch!");
  return err;
}

OSStatus AudioDevice::SetBufferSize(UInt32 buffersize) {
  OSStatus err = noErr;
  UInt32 size = sizeof(UInt32);
  AudioObjectPropertyAddress addr = { kAudioDevicePropertyBufferFrameSize, (mIsInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput), 0 };
  err = AudioObjectSetPropertyData(mID, &addr, 0, NULL, size, &buffersize);
  AudioObjectGetPropertyData(mID, &addr, 0, NULL, &size, &mBufferSizeFrames);
  if(mBufferSizeFrames != buffersize) printf("buffer size mismatch!");
  return err;
}

UInt32 AudioDevice::getStreamPhysicalBitDepth(bool isInput) {
  AudioStreamBasicDescription asbd;
  UInt32 size = sizeof(asbd);
  AudioObjectPropertyAddress addr = { kAudioStreamPropertyPhysicalFormat, (isInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput), kAudioObjectPropertyElementMaster };
  AudioObjectGetPropertyData(mID, &addr, 0, NULL, &size, &asbd);
  return asbd.mBitsPerChannel;
}
