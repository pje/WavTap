#ifndef __AudioTee_h__
#define __AudioTee_h__
#include "AudioDevice.h"
#include "CARingBuffer.h"

class AudioTee {
public:
  AudioTee(AudioDeviceID inputDeviceID, AudioDeviceID outputDeviceID);
  ~AudioTee() {}
  void Start();
  bool Stop();
  void saveHistoryBuffer(const char* fileName, UInt32 secondsRequested);
  Byte *mWorkBuf;
  UInt32 mSecondsInHistoryBuffer;
  CARingBuffer *mHistBuf;
  UInt32 mHistoryBufferMaxByteSize;
  UInt32 mBufferSize;
  AudioDevice mInputDevice;
  AudioDevice mOutputDevice;
  bool mFirstRun;
  bool mRunning;
  bool mMuting;
  bool mThruing;
protected:
  static OSStatus InputIOProc(AudioDeviceID inDevice, const AudioTimeStamp *inNow, const AudioBufferList *inInputData, const AudioTimeStamp *inInputTime, AudioBufferList *outOutputData, const AudioTimeStamp *inOutputTime, void *inClientData);
  static OSStatus OutputIOProc(AudioDeviceID inDevice, const AudioTimeStamp *inNow, const AudioBufferList *inInputData, const AudioTimeStamp *inInputTime, AudioBufferList *outOutputData, const AudioTimeStamp *inOutputTime, void *inClientData);
  void ComputeThruOffset();
  Float64 mSampleRate;
  AudioDeviceIOProcID mInputIOProcID;
  AudioDeviceIOProcID mOutputIOProcID;
  AudioDeviceIOProc mOutputIOProc;
  UInt32 mHistoryBufferByteSize;
  UInt32 mHistoryBufferHeadOffsetFrameNumber;
};

#endif
