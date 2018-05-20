#ifndef __AudioDevice_hpp__
#define __AudioDevice_hpp__
#include <CoreServices/CoreServices.h>
#include <CoreAudio/CoreAudio.h>
#include <sys/syslog.h>

#define DEBUG 1

#ifdef DEBUG
  #define Debug(inFormat, ...) syslog(LOG_NOTICE, "%s: %s", __func__, inFormat, ## __VA_ARGS__)
  #define Fail(message, status) Debug(message); return status;
#else
  #define Debug(inFormat, ...)
  #define Fail(message, status) return(status);
#endif

#if TARGET_RT_BIG_ENDIAN
#   define FourCC2Str(fourcc) (const char[]) { *((char*)&fourcc), *(((char*)&fourcc)+1), *(((char*)&fourcc)+2), *(((char*)&fourcc)+3), 0 }
#else
#   define FourCC2Str(fourcc) (const char[]) { *(((char*)&fourcc)+3), *(((char*)&fourcc)+2), *(((char*)&fourcc)+1), *(((char*)&fourcc)+0), 0 }
#endif

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
