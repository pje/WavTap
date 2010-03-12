/*
  File:SoundflowerEngine.h

  Version:1.0.1
    ma++ ingalls  |  cycling '74  |  Copyright (C) 2004  |  soundflower.com
    
    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version 2
    of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    
    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/

#ifndef _SoundflowerENGINE_H
#define _SoundflowerENGINE_H

#include <IOKit/audio/IOAudioEngine.h>
#include "SoundflowerDevice.h"


class SoundflowerEngine : public IOAudioEngine
{
    OSDeclareDefaultStructors(SoundflowerEngine)
    
	UInt32				mBufferSize;
	void*				mBuffer;				// input/output buffer
    float*				mThruBuffer;			// intermediate buffer to pass in-->out
	
	IOAudioStream*		outputStream;
	IOAudioStream*		inputStream;
    	
	UInt32				mLastValidSampleFrame;
    
    IOTimerEventSource*	timerEventSource;
    
    UInt32				blockSize;				// In sample frames -- fixed, as defined in the Info.plist (e.g. 8192)
    UInt32				numBlocks;
    UInt32				currentBlock;
    
    UInt64				blockTimeoutNS;
    UInt64				nextTime;				// the estimated time the timer will fire next

    bool				duringHardwareInit;
    
	
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


#endif /* _SoundflowerENGINE_H */
