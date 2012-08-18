#ifndef __AudioRingBuffer_h__
#define __AudioRingBuffer_h__

#include <CoreServices/CoreServices.h>

class AudioRingBuffer {

public:
  AudioRingBuffer(UInt32 bytesPerFrame, UInt32 capacityFrames);
  ~AudioRingBuffer();
  void Allocate(UInt32 bytesPerFrame, UInt32 capacityFrames);
  void Clear();
  bool Store(const Byte *data, UInt32 nFrames, SInt64 frameNumber);
  double Fetch(Byte *data, UInt32 nFrames, SInt64 frameNumber);

protected:
  UInt32 FrameOffset(SInt64 frameNumber) { return (mStartOffset + UInt32(frameNumber - mStartFrame) * mBytesPerFrame) % mCapacityBytes; }

protected:
  UInt32 mBytesPerFrame;
  UInt32 mCapacityFrames;
  UInt32 mCapacityBytes;
  Byte *mBuffer;
  UInt32 mStartOffset;
  SInt64 mStartFrame;
  SInt64 mEndFrame;
};

#endif // __AudioRingBuffer_h__
