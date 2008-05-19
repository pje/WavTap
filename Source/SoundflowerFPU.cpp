/*
 *  SoundflowerFPU.c
 *  Soundflower
 */

#include "SoundflowerEngine.h"

IOReturn SoundflowerEngine::clipOutputSamples(const void *mixBuf, void *sampleBuf, UInt32 firstSampleFrame, UInt32 numSampleFrames, const IOAudioStreamFormat *streamFormat, IOAudioStream *audioStream)
{
    UInt32 channelCount = streamFormat->fNumChannels;
    UInt32 offset = firstSampleFrame * channelCount;
    UInt32 byteOffset = offset * sizeof(float);
    UInt32 numBytes = numSampleFrames * channelCount * sizeof(float);
    
	if (((SoundflowerDevice *)audioDevice)->mMuteIn[0])
	{
		memset((UInt8 *)thruBuffer + byteOffset, 0, numBytes);
	}
	else
	{
		memcpy((UInt8 *)thruBuffer + byteOffset, (UInt8 *)mixBuf + byteOffset, numBytes);

		float masterGain =   ((SoundflowerDevice *)audioDevice)->mGain[0]/((float)SoundflowerDevice::kGainMax);
		float masterVolume = ((SoundflowerDevice *)audioDevice)->mVolume[0]/((float)SoundflowerDevice::kVolumeMax);

		for(UInt32 channel = 0; channel < channelCount; channel++)
		{
			SInt32 channelMute =  ((SoundflowerDevice *)audioDevice)->mMuteIn[channel+1];
			float channelGain =   ((SoundflowerDevice *)audioDevice)->mGain[channel+1]/((float)SoundflowerDevice::kGainMax);
			float channelVolume = ((SoundflowerDevice *)audioDevice)->mVolume[channel+1]/((float)SoundflowerDevice::kVolumeMax);
			float adjustment = masterVolume * channelVolume * masterGain * channelGain;
			
			for(UInt32 channelBufferIterator = 0; channelBufferIterator < numSampleFrames; channelBufferIterator++)
			{
				if( channelMute )
					thruBuffer[offset + channelBufferIterator*channelCount + channel] = 0;
				else
					thruBuffer[offset + channelBufferIterator*channelCount + channel] *= adjustment;
			}
		}
	}

	return kIOReturnSuccess;
}


// This is called when client apps need input audio.  Here we give them saved audio from the clip routine.

IOReturn SoundflowerEngine::convertInputSamples(const void *sampleBuf, void *destBuf, UInt32 firstSampleFrame, UInt32 numSampleFrames, const IOAudioStreamFormat *streamFormat, IOAudioStream *audioStream)
{
    UInt32 offset;
    UInt32 frameSize = streamFormat->fNumChannels * sizeof(float);
    offset = firstSampleFrame * frameSize;
              
    if (((SoundflowerDevice *)audioDevice)->mMuteOut[0])
        memset((UInt8 *)destBuf, 0, numSampleFrames * frameSize);
    else
        memcpy((UInt8 *)destBuf, (UInt8 *)thruBuffer + offset, numSampleFrames * frameSize);

    return kIOReturnSuccess;
}
