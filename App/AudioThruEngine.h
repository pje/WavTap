#ifndef __AudioThruEngine_h__
#define __AudioThruEngine_h__

#include "AudioDevice.h"
#include "TPCircularBuffer.h"

class AudioThruEngine {
public:
  AudioThruEngine(AudioDeviceID inputDeviceID, AudioDeviceID outputDeviceID);
  ~AudioThruEngine() {}
  void Start();
  bool Stop();
  void SetDevices(AudioDeviceID input, AudioDeviceID output);
  void Mute(bool mute = true) { mMuting = mute; }
  bool IsRunning() { return mRunning; }
  void EnableThru(bool enable) { mThruing = enable; }
  void SetBufferSize(UInt32 size);
  double GetThruTime() { return mThruTime; }
  SInt32 GetThruLatency() { return mActualThruLatency; }
  UInt32 GetOutputNchnls();
  AudioDeviceID GetOutputDeviceID() { return mOutputDevice.mID; }
  AudioDeviceID GetInputDeviceID() { return mInputDevice.mID; }
  OSStatus MatchSampleRates(AudioObjectID changedDeviceID);
  void saveHistoryBuffer(const char* fileName);
  Byte *mWorkBuf;
  TPCircularBuffer *mHistBuf;
  UInt32 mHistoryBufferMaxByteSize;
  UInt32 mBufferSize;
  SInt32 mExtraLatencyFrames;
  AudioDevice mInputDevice, mOutputDevice;
  bool mFirstRun;

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
  bool mRunning;
  bool mMuting;
  bool mThruing;
  IOProcState mInputProcState, mOutputProcState;
  Float64 mLastInputSampleCount, mIODeltaSampleCount;
  SInt32 mActualThruLatency;
  Float64 mSampleRate;
  Float64 mInToOutSampleOffset; // subtract from the output time to obtain input time
  double mInputLoad, mOutputLoad;
  double mThruTime;
  AudioDeviceIOProcID mInputIOProcID;
  AudioDeviceIOProcID mOutputIOProcID;
  AudioDeviceIOProc mOutputIOProc;
  UInt32 mHistoryBufferByteSize;
};

#endif // __AudioThruEngine_h__
