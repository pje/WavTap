#ifndef _SAMPLEAUDIODEVICE_H
#define _SAMPLEAUDIODEVICE_H

#include <IOKit/audio/IOAudioDevice.h>

#define NUM_CHANS 64
#define AUDIO_ENGINES_KEY "AudioEngines"
#define DESCRIPTION_KEY "Description"
#define BLOCK_SIZE_KEY "BlockSize"
#define NUM_BLOCKS_KEY "NumBlocks"
#define NUM_STREAMS_KEY "NumStreams"
#define FORMATS_KEY "Formats"
#define SAMPLE_RATES_KEY "SampleRates"
#define SEPARATE_STREAM_BUFFERS_KEY "SeparateStreamBuffers"
#define SEPARATE_INPUT_BUFFERS_KEY "SeparateInputBuffers"
#define SoundflowerDevice com_cycling74_driver_SoundflowerDevice

class SoundflowerEngine;

class SoundflowerDevice : public IOAudioDevice
{
  OSDeclareDefaultStructors(SoundflowerDevice)
  friend class SoundflowerEngine;
  static const SInt32 kVolumeMax;
  static const SInt32 kGainMax;
  SInt32 mVolume[NUM_CHANS+1];
  SInt32 mMuteOut[NUM_CHANS+1];
  SInt32 mMuteIn[NUM_CHANS+1];
  SInt32 mGain[NUM_CHANS+1];
  virtual bool initHardware(IOService *provider);
  virtual bool createAudioEngines();
  virtual bool initControls(SoundflowerEngine *audioEngine);
  static IOReturn volumeChangeHandler(IOService *target, IOAudioControl *volumeControl, SInt32 oldValue, SInt32 newValue);
  virtual IOReturn volumeChanged(IOAudioControl *volumeControl, SInt32 oldValue, SInt32 newValue);
  static IOReturn outputMuteChangeHandler(IOService *target, IOAudioControl *muteControl, SInt32 oldValue, SInt32 newValue);
  virtual IOReturn outputMuteChanged(IOAudioControl *muteControl, SInt32 oldValue, SInt32 newValue);
  static IOReturn gainChangeHandler(IOService *target, IOAudioControl *gainControl, SInt32 oldValue, SInt32 newValue);
  virtual IOReturn gainChanged(IOAudioControl *gainControl, SInt32 oldValue, SInt32 newValue);
  static IOReturn inputMuteChangeHandler(IOService *target, IOAudioControl *muteControl, SInt32 oldValue, SInt32 newValue);
  virtual IOReturn inputMuteChanged(IOAudioControl *muteControl, SInt32 oldValue, SInt32 newValue);
};

#endif // _SAMPLEAUDIODEVICE_H
