#ifndef __AudioThruEngine_h__
#define __AudioThruEngine_h__

#include "AudioDevice.h"

class CARingBuffer;
class AudioRingBuffer;

class AudioThruEngine {
public:
  AudioThruEngine();
  ~AudioThruEngine();

  void SetDevices(AudioDeviceID input, AudioDeviceID output);
  void InitInputDevice(AudioDeviceID input);
  void InitOutputDevice(AudioDeviceID output);
  void Start();
  bool Stop();
  void Mute(bool mute = true) { mMuting = mute; }
  bool IsRunning() { return mRunning; }
  void EnableThru(bool enable) { mThruing = enable; }
  void SetBufferSize(UInt32 size);
  double GetThruTime() { return mThruTime; }
  SInt32 GetThruLatency() { return mActualThruLatency; }
  UInt32 GetOutputNchnls();
  AudioDeviceID GetOutputDevice() { return mOutputDeviceID.mID; }
  AudioDeviceID GetInputDevice() { return mInputDevice.mID; }
  OSStatus MatchSampleRate(bool useInputDevice);

  void SetChannelMap(int ch, int val) { mChannelMap[ch] = val; }   // valid values are 0 to nchnls-1;  -1 = off
  int GetChannelMap(int ch) { return mChannelMap[ch]; }
  Byte *mWorkBuf;

protected:
  enum IOProcState {
    kOff,
    kStarting,
    kRunning,
    kStopRequested
  };

  static OSStatus InputIOProc (AudioDeviceID inDevice,
                  const AudioTimeStamp *inNow,
                  const AudioBufferList *inInputData,
                  const AudioTimeStamp *inInputTime,
                  AudioBufferList *outOutputData,
                  const AudioTimeStamp *inOutputTime,
                  void *inClientData);

  static OSStatus OutputIOProc (AudioDeviceID inDevice,
                  const AudioTimeStamp *inNow,
                  const AudioBufferList *inInputData,
                  const AudioTimeStamp *inInputTime,
                  AudioBufferList *outOutputData,
                  const AudioTimeStamp *inOutputTime,
                  void *inClientData);

  void ComputeThruOffset();
  AudioDevice mInputDevice, mOutputDeviceID;
  bool mRunning;
  bool mMuting;
  bool mThruing;
  IOProcState mInputProcState, mOutputProcState;
  Float64 mLastInputSampleCount, mIODeltaSampleCount;
  UInt32 mBufferSize;
  SInt32 mExtraLatencyFrames;
  SInt32 mActualThruLatency;
  Float64 mSampleRate;
  Float64 mInToOutSampleOffset; // subtract from the output time to obtain input time
//  CARingBuffer *mInputBuffer;
  AudioRingBuffer *mInputBuffer;
  double mInputLoad, mOutputLoad;
  double mThruTime;
  int mChannelMap[64];
  AudioDeviceIOProc mOutputIOProc;
};

#endif // __AudioThruEngine_h__
