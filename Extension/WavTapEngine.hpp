#ifndef _WavTapENGINE_HPP
#define _WavTapENGINE_HPP

#include <IOKit/audio/IOAudioEngine.h>
#include "WavTapDevice.hpp"

class WavTapEngine : public IOAudioEngine {
  OSDeclareDefaultStructors(WavTapEngine);
  UInt32 mBufferSize;
  void *mBuffer;
  float *mThruBuffer;
  IOAudioStream *outputStream;
  IOAudioStream *inputStream;
  UInt32 mLastValidSampleFrame;
  IOTimerEventSource *timerEventSource;
  UInt32 blockSize;
  UInt32 numBlocks;
  UInt32 currentBlock;
  UInt64 blockTimeoutNS;
  UInt64 nextTime;
  bool duringHardwareInit;
  float logTable[100];
public:
  virtual bool init(OSDictionary *properties);
  virtual void free();
  virtual bool initHardware(IOService *provider);
  virtual bool createAudioStreams(IOAudioSampleRate *initialSampleRate);
  virtual IOReturn performAudioEngineStart();
  virtual IOReturn performAudioEngineStop();
  virtual UInt32 getCurrentSampleFrame();
  virtual IOReturn performFormatChange(IOAudioStream *audioStream, const IOAudioStreamFormat *newFormat, const IOAudioSampleRate *newSampleRate);
  virtual IOReturn clipOutputSamples(const void *mixBuf, void *sampleBuf, UInt32 firstSampleFrame, UInt32 numSampleFrames, const IOAudioStreamFormat *streamFormat, IOAudioStream *audioStream);
  virtual IOReturn convertInputSamples(const void *sampleBuf, void *destBuf, UInt32 firstSampleFrame, UInt32 numSampleFrames, const IOAudioStreamFormat *streamFormat, IOAudioStream *audioStream);
  static void ourTimerFired(OSObject *target, IOTimerEventSource *sender);
};

#endif
