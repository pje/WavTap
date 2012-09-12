#include "WavFileUtils.h"
#include <iostream>
#include <fstream>
#include <stdio.h>

void WavFileUtils::writeWavFileHeaders(const char* fileName, UInt32 numAudioBytes, UInt32 sampleRate, UInt32 bitsPerSample){
  std::ofstream file(fileName, std::ios::binary);
  uint32_t totalDataLen = numAudioBytes + 44;
  long byteRate = sampleRate * 16.0 * 2/8;
  uint32_t headerSize = 44;
  Byte *header = new Byte[headerSize];
  header[0] = 'R';
  header[1] = 'I';
  header[2] = 'F';
  header[3] = 'F';
  header[4] = (Byte) (totalDataLen & 0xff);
  header[5] = (Byte) ((totalDataLen >> 8) & 0xff);
  header[6] = (Byte) ((totalDataLen >> 16) & 0xff);
  header[7] = (Byte) ((totalDataLen >> 24) & 0xff);
  header[8] = 'W';
  header[9] = 'A';
  header[10] = 'V';
  header[11] = 'E';
  header[12] = 'f';
  header[13] = 'm';
  header[14] = 't';
  header[15] = ' ';
  header[16] = 16;
  header[17] = 0;
  header[18] = 0;
  header[19] = 0;
  header[20] = 1;
  header[21] = 0;
  header[22] = (Byte) 2;
  header[23] = 0;
  header[24] = (Byte) (sampleRate & 0xff);
  header[25] = (Byte) ((sampleRate >> 8) & 0xff);
  header[26] = (Byte) ((sampleRate >> 16) & 0xff);
  header[27] = (Byte) ((sampleRate >> 24) & 0xff);
  header[28] = (Byte) (byteRate & 0xff);
  header[29] = (Byte) ((byteRate >> 8) & 0xff);
  header[30] = (Byte) ((byteRate >> 16) & 0xff);
  header[31] = (Byte) ((byteRate >> 24) & 0xff);
  header[32] = (Byte) (2 * 8 / 8);  // block align
  header[33] = 0;
  header[34] = bitsPerSample;
  header[35] = 0;
  header[36] = 'd';
  header[37] = 'a';
  header[38] = 't';
  header[39] = 'a';
  header[40] = (Byte) (numAudioBytes & 0xff);
  header[41] = (Byte) ((numAudioBytes >> 8) & 0xff);
  header[42] = (Byte) ((numAudioBytes >> 16) & 0xff);
  header[43] = (Byte) ((numAudioBytes >> 24) & 0xff);
  file.seekp(0);
  file.write((char *)header, headerSize);
  file.close();
  delete[] header;
}

void WavFileUtils::writeWavFileSizeHeaders(const char* fileName, UInt32 numAudioBytes){
  std::fstream file(fileName, std::ios::binary | std::ios::out | std::ios::in);
  int32_t totalDataLen = numAudioBytes + 44;
  Byte *header = new Byte[4];
  header[0] = (Byte) (totalDataLen & 0xff);
  header[1] = (Byte) ((totalDataLen >> 8) & 0xff);
  header[2] = (Byte) ((totalDataLen >> 16) & 0xff);
  header[3] = (Byte) ((totalDataLen >> 24) & 0xff);
  file.seekp(4, std::ios::beg);
  file.write((char *)header, 4);
  header[0] = (Byte) (numAudioBytes & 0xff);
  header[1] = (Byte) ((numAudioBytes >> 8) & 0xff);
  header[2] = (Byte) ((numAudioBytes >> 16) & 0xff);
  header[3] = (Byte) ((numAudioBytes >> 24) & 0xff);
  file.seekp(40, std::ios::beg);
  file.write((char *)header, 4);
  file.close();
  delete[] header;
}
