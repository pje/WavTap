/*	Copyright: 	© Copyright 2004 Apple Computer, Inc. All rights reserved.

	Disclaimer:	IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc.
			("Apple") in consideration of your agreement to the following terms, and your
			use, installation, modification or redistribution of this Apple software
			constitutes acceptance of these terms.  If you do not agree with these terms,
			please do not use, install, modify or redistribute this Apple software.

			In consideration of your agreement to abide by the following terms, and subject
			to these terms, Apple grants you a personal, non-exclusive license, under Apple’s
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
	AudioThruEngine.h
	
=============================================================================*/

#ifndef __AudioThruEngine_h__
#define __AudioThruEngine_h__

#include "AudioDevice.h"

class AudioRingBuffer;

class AudioThruEngine {
public:
	AudioThruEngine();
	~AudioThruEngine();
	
	void	SetDevices(AudioDeviceID input, AudioDeviceID output);
	void	SetInputDevice(AudioDeviceID input);
	void	SetOutputDevice(AudioDeviceID output);
	
	void	Start();
	bool	Stop();
	void	Mute(bool mute = true) { mMuting = mute; }
	bool	IsRunning() { return mRunning; }
	
	void	EnableThru(bool enable) { mThruing = enable; }
	void	SetBufferSize(UInt32 size);
	void	SetInputLoad(double load) { mInputLoad = load; }
	void	SetOutputLoad(double load) { mOutputLoad = load; }
	
	void	SetExtraLatency(SInt32 frames);
	double	GetThruTime() { return mThruTime; }
	SInt32	GetThruLatency() { return mActualThruLatency; }
	
	UInt32	GetOutputNchnls();
	AudioDeviceID	GetOutputDevice() { return mOutputDevice.mID; }
	AudioDeviceID	GetInputDevice() { return mInputDevice.mID; }
	
	OSStatus	MatchSampleRate(bool useInputDevice);
	
	// valid values are 0 to nchnls-1;  -1 = off
	void	SetChannelMap(int ch, int val) { mChannelMap[ch] = val; }
	int		GetChannelMap(int ch) { return mChannelMap[ch]; }
	
//	char *	GetErrorMessage() { return mErrorMessage; }

	Byte			*mWorkBuf;
	
	//iSchemy's edit
	void			SetCloneChannels(bool clone) { mCloneChannels = clone; }
	bool			CloneChannels() { return mCloneChannels; }
	
	
protected:
	enum IOProcState {
		kOff,
		kStarting,
		kRunning,
		kStopRequested
	};
	
//	void	ApplyLoad(double load);

	static OSStatus InputIOProc (	AudioDeviceID			inDevice,
									const AudioTimeStamp*	inNow,
									const AudioBufferList*	inInputData,
									const AudioTimeStamp*	inInputTime,
									AudioBufferList*		outOutputData,
									const AudioTimeStamp*	inOutputTime,
									void*					inClientData);

	static OSStatus OutputIOProc (	AudioDeviceID			inDevice,
									const AudioTimeStamp*	inNow,
									const AudioBufferList*	inInputData,
									const AudioTimeStamp*	inInputTime,
									AudioBufferList*		outOutputData,
									const AudioTimeStamp*	inOutputTime,
									void*					inClientData);

	static OSStatus OutputIOProc16 (	AudioDeviceID			inDevice,
									const AudioTimeStamp*	inNow,
									const AudioBufferList*	inInputData,
									const AudioTimeStamp*	inInputTime,
									AudioBufferList*		outOutputData,
									const AudioTimeStamp*	inOutputTime,
									void*					inClientData);
									
	void	ComputeThruOffset();

	AudioDevice		mInputDevice, mOutputDevice;
	bool			mRunning;
	bool			mMuting;
	bool			mThruing;
	IOProcState		mInputProcState, mOutputProcState;
	Float64			mLastInputSampleCount, mIODeltaSampleCount;
	UInt32			mBufferSize;
	SInt32			mExtraLatencyFrames;
	SInt32			mActualThruLatency;
	Float64			mSampleRate;
	Float64			mInToOutSampleOffset;		// subtract from the output time to obtain input time
	AudioRingBuffer *mInputBuffer;
	double			mInputLoad, mOutputLoad;
	double			mThruTime;
	
	int				mChannelMap[64];
	AudioDeviceIOProc mOutputIOProc;
	//char			mErrorMessage[128];
	
	// iSchemy's edit
	bool			mCloneChannels;
	// end

};


#endif // __AudioThruEngine_h__
