/*	Copyright: 	© Copyright 2004 Apple Computer, Inc. All rights reserved.

	Disclaimer:	IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc.
			("Apple") in consideration of your agreement to the following terms, and your
			use, installation, modification or redistribution of this Apple software
			constitutes acceptance of these terms.  If you do not agree with these terms,
			please do not use, install, modify or redistribute this Apple software.

			In consideration of your agreement to abide by the following terms, and subject
			to these terms, Apple grants you a personal, non-exclusive license, under AppleÕs
			copyrights in this original Apple software (the "Apple Software"), to use,
			reproduce, modify and redistribute the Apple Software, with or without
			modifications, in source and/or binary forms; provided that if you redistribute
			the Apple Software in its entirety and without modifications, you must retain
			this notice and the following text and disclaimers in all such redistributions of
			the Apple Software.  Neither the name, trademarks, service marks or logos of
			Apple Computer, Inc. may be used to endorse or promote products derived from the
			Apple Software without specific prior written permission from Apple.  Except as
			expressly stated in this notice, no other rights or licenses, express or implied,
			are granted by Apple herein, including but not limited to any patent rights that
			may be infringed by your derivative works or by other works in which the Apple
			Software may be incorporated.

			The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
			WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
			WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
			PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
			COMBINATION WITH YOUR PRODUCTS.

			IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
			CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
			GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
			ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
			OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT
			(INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN
			ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
/*=============================================================================
	AudioRingBuffer.cpp
	
=============================================================================*/

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

void	AudioRingBuffer::Allocate(UInt32 bytesPerFrame, UInt32 capacityFrames)
{
	if (mBuffer)
		free(mBuffer);
	
	mBytesPerFrame = bytesPerFrame;
	mCapacityFrames = capacityFrames;
	mCapacityBytes = bytesPerFrame * capacityFrames;
	mBuffer = (Byte *)malloc(mCapacityBytes);
	Clear();
}

void	AudioRingBuffer::Clear()
{
	memset(mBuffer, 0, mCapacityBytes);
	mStartOffset = 0;
	mStartFrame = 0;
	mEndFrame = 0;
}

bool	AudioRingBuffer::Store(const Byte *data, UInt32 nFrames, SInt64 startFrame)
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

double	AudioRingBuffer::Fetch(Byte *data, UInt32 nFrames, SInt64 startFrame)
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
