#ifndef __AudioDevice_h__
#define __AudioDevice_h__

#include <CoreServices/CoreServices.h>
#include <CoreAudio/CoreAudio.h>

class AudioDevice {

public:
  AudioDevice() : mID(kAudioDeviceUnknown) { }
  AudioDevice(AudioDeviceID devid, bool isInput) { Init(devid, isInput); }
  void Init(AudioDeviceID devid, bool isInput);
  bool Valid() { return mID != kAudioDeviceUnknown; }
  void SetBufferSize(UInt32 size);
  OSStatus SetSampleRate(Float64 sr);
  void UpdateFormat();
  int CountChannels();
  char *GetName(char *buf, UInt32 maxlen);

public:
  AudioDeviceID mID;
  bool mIsInput;
  UInt32 mSafetyOffset;
  UInt32 mBufferSizeFrames;
  AudioStreamBasicDescription mFormat;
};

#endif // __AudioDevice_h__
