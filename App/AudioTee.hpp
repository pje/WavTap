#ifndef __AudioTee_hpp__
#define __AudioTee_hpp__
#include "AudioDevice.hpp"
#include "CARingBuffer.h"

class AudioTee {
public:
  AudioTee(AudioDeviceID inputDeviceID, AudioDeviceID outputDeviceID);
  ~AudioTee() {}
  void start();
  void stop();
  void saveHistoryBuffer(const char* fileName, UInt32 secondsRequested);
  AudioDevice mInputDevice;
  AudioDevice mOutputDevice;
  UInt32 mSecondsInHistoryBuffer;
protected:
  Byte *mWorkBuf;
  CARingBuffer *mHistBuf;
  UInt32 mHistoryBufferMaxByteSize;
  UInt32 mBufferSize;
  static OSStatus InputIOProc(AudioDeviceID inDevice, const AudioTimeStamp *inNow, const AudioBufferList *inInputData, const AudioTimeStamp *inInputTime, AudioBufferList *outOutputData, const AudioTimeStamp *inOutputTime, void *inClientData);
  static OSStatus OutputIOProc(AudioDeviceID inDevice, const AudioTimeStamp *inNow, const AudioBufferList *inInputData, const AudioTimeStamp *inInputTime, AudioBufferList *outOutputData, const AudioTimeStamp *inOutputTime, void *inClientData);
  AudioDeviceIOProcID mInputIOProcID;
  AudioDeviceIOProcID mOutputIOProcID;
  AudioDeviceIOProc mOutputIOProc;
  UInt32 mHistoryBufferByteSize;
  UInt32 mHistoryBufferHeadOffsetFrameNumber;
};

#endif
