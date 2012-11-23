#ifndef __AudioDevice_hpp__
#define __AudioDevice_hpp__
#include <CoreServices/CoreServices.h>
#include <CoreAudio/CoreAudio.h>

class AudioDevice {
public:
  AudioDevice(AudioDeviceID devid, bool isInput);
  OSStatus SetBufferSize(UInt32 size);
  OSStatus SetSampleRate(Float64 sr);
  OSStatus ReloadStreamFormat();
  char *GetName(char *buf, UInt32 maxlen);
  UInt32 getStreamPhysicalBitDepth(bool isInput);
  AudioDeviceID mID;
  bool mIsInput;
  UInt32 mSafetyOffset;
  UInt32 mBufferSizeFrames;
  AudioStreamBasicDescription mFormat;
};

#endif
