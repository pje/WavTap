#include "AudioRingBuffer.h"

AudioRingBuffer::AudioRingBuffer(UInt32 bytesPerFrame, UInt32 capacityFrames) :
  mBuffer(NULL)
{
  Allocate(bytesPerFrame, capacityFrames);
}

AudioRingBuffer::~AudioRingBuffer()
{
  if (mBuffer)
    free(mBuffer);
}

void  AudioRingBuffer::Allocate(UInt32 bytesPerFrame, UInt32 capacityFrames)
{
  if (mBuffer)
    free(mBuffer);

  mBytesPerFrame = bytesPerFrame;
  mCapacityFrames = capacityFrames;
  mCapacityBytes = bytesPerFrame * capacityFrames;
  mBuffer = (Byte *)malloc(mCapacityBytes);
  Clear();
}

void  AudioRingBuffer::Clear()
{
  memset(mBuffer, 0, mCapacityBytes);
  mStartOffset = 0;
  mStartFrame = 0;
  mEndFrame = 0;
}

bool  AudioRingBuffer::Store(const Byte *data, UInt32 nFrames, SInt64 startFrame)
{
  if (nFrames > mCapacityFrames) return false;

  // $$$ we have an unaddressed critical region here
  // reading and writing could well be in separate threads

  SInt64 endFrame = startFrame + nFrames;
  if (startFrame >= mEndFrame + mCapacityFrames)
    // writing more than one buffer ahead -- fine but that means that everything we have is now too far in the past
    Clear();

  if (mStartFrame == 0) {
    // empty buffer
    mStartOffset = 0;
    mStartFrame = startFrame;
    mEndFrame = endFrame;
    memcpy(mBuffer, data, nFrames * mBytesPerFrame);
  } else {
    UInt32 offset0, offset1, nBytes;
    if (endFrame > mEndFrame) {
      // advancing (as will be usual with sequential stores)

      if (startFrame > mEndFrame) {
        // we are skipping some samples, so zero the range we are skipping
        offset0 = FrameOffset(mEndFrame);
        offset1 = FrameOffset(startFrame);
        if (offset0 < offset1)
          memset(mBuffer + offset0, 0, offset1 - offset0);
        else {
          nBytes = mCapacityBytes - offset0;
          memset(mBuffer + offset0, 0, nBytes);
          memset(mBuffer, 0, offset1);
        }
      }
      mEndFrame = endFrame;

      // except for the case of not having wrapped yet, we will normally
      // have to advance the start
      SInt64 newStart = mEndFrame - mCapacityFrames;
      if (newStart > mStartFrame) {
        mStartOffset = (mStartOffset + (newStart - mStartFrame) * mBytesPerFrame) % mCapacityBytes;
        mStartFrame = newStart;
      }
    }
    // now everything is lined up and we can just write the new data
    offset0 = FrameOffset(startFrame);
    offset1 = FrameOffset(endFrame);
    if (offset0 < offset1)
      memcpy(mBuffer + offset0, data, offset1 - offset0);
    else {
      nBytes = mCapacityBytes - offset0;
      memcpy(mBuffer + offset0, data, nBytes);
      memcpy(mBuffer, data + nBytes, offset1);
    }
  }
  //printf("Store - buffer times: %.0f - %.0f, writing %.0f - %.0f\n", double(mStartFrame), double(mEndFrame), double(startFrame), double(endFrame));

  return true;
}

double  AudioRingBuffer::Fetch(Byte *data, UInt32 nFrames, SInt64 startFrame)
{
  SInt64 endFrame = startFrame + nFrames;
  if (startFrame < mStartFrame || endFrame > mEndFrame) {
    //printf("error - buffer times: %.0f - %.0f, reading for %.0f - %.0f\n", double(mStartFrame), double(mEndFrame), double(startFrame), double(endFrame));
    if (startFrame < mStartFrame)
      return double(startFrame - mStartFrame);
    else
      return double(endFrame - mEndFrame);
  }

  UInt32 offset0 = FrameOffset(startFrame);
  UInt32 offset1 = FrameOffset(endFrame);

  if (offset0 < offset1)
    memcpy(data, mBuffer + offset0, offset1 - offset0);
  else {
    UInt32 nBytes = mCapacityBytes - offset0;
    memcpy(data, mBuffer + offset0, nBytes);
    memcpy(data + nBytes, mBuffer, offset1);
  }
  return double((mEndFrame - nFrames) - startFrame);
}
