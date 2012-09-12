#ifndef __WavTap__WavFileUtils__
#define __WavTap__WavFileUtils__
#include <CoreAudio/CoreAudio.h>
#include <iostream>
class WavFileUtils {
public:
  static void writeWavFileHeaders(const char* fileName, UInt32 numAudioBytes, UInt32 sampleRate, UInt32 bitsPerSample);
  static void writeWavFileSizeHeaders(const char* fileName, UInt32 numAudioBytes);
};
#endif
