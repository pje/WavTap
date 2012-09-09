/*
    WavTap is derived from Apple's 'PhantomAudioDriver'
    sample code.  It uses the same timer mechanism to simulate a hardware
    interrupt, with some additional code to compensate for the software
    timer's inconsistencies.

    WavTap basically copies the mixbuffer and presents it to clients
    as an input buffer, allowing applications to send audio one another.
*/

#include "WavTapDevice.h"
#include "WavTapEngine.h"
#include <IOKit/audio/IOAudioControl.h>
#include <IOKit/audio/IOAudioLevelControl.h>
#include <IOKit/audio/IOAudioToggleControl.h>
#include <IOKit/audio/IOAudioDefines.h>
#include <IOKit/IOLib.h>

#define super IOAudioDevice

OSDefineMetaClassAndStructors(WavTapDevice, IOAudioDevice)

// There should probably only be one of these? This needs to be
// set to the last valid position of the log lookup table.
const SInt32 WavTapDevice::kVolumeMax = 99;
const SInt32 WavTapDevice::kGainMax = 99;




bool WavTapDevice::initHardware(IOService *provider)
{
    bool result = false;

    if (!super::initHardware(provider))
        goto Done;

    setDeviceName("WavTap");
    setDeviceShortName("WavTap");
    setManufacturerName("WavTap");

    if (!createAudioEngines())
        goto Done;

    result = true;

Done:

    return result;
}


bool WavTapDevice::createAudioEngines()
{
    OSArray*				audioEngineArray = OSDynamicCast(OSArray, getProperty(AUDIO_ENGINES_KEY));
    OSCollectionIterator*	audioEngineIterator;
    OSDictionary*			audioEngineDict;

    if (!audioEngineArray) {
        IOLog("WavTapDevice[%p]::createAudioEngine() - Error: no AudioEngine array in personality.\n", this);
        return false;
    }

	audioEngineIterator = OSCollectionIterator::withCollection(audioEngineArray);
    if (!audioEngineIterator) {
		IOLog("WavTapDevice: no audio engines available.\n");
		return true;
	}

    while ((audioEngineDict = (OSDictionary*)audioEngineIterator->getNextObject())) {
		WavTapEngine*	audioEngine = NULL;

        if (OSDynamicCast(OSDictionary, audioEngineDict) == NULL)
            continue;

		audioEngine = new WavTapEngine;
        if (!audioEngine)
			continue;

        if (!audioEngine->init(audioEngineDict))
			continue;

		initControls(audioEngine);
        activateAudioEngine(audioEngine);	// increments refcount and manages the object
        audioEngine->release();				// decrement refcount so object is released when the manager eventually releases it
    }

    audioEngineIterator->release();
    return true;
}


#define addControl(control, handler) \
    if (!control) {\
		IOLog("WavTap failed to add control.\n");	\
		return false; \
	} \
    control->setValueChangeHandler(handler, this); \
    audioEngine->addDefaultAudioControl(control); \
    control->release();

bool WavTapDevice::initControls(WavTapEngine* audioEngine)
{
    IOAudioControl*	control = NULL;

    for (UInt32 channel=0; channel <= NUM_CHANS; channel++) {
        mVolume[channel] = mGain[channel] = kVolumeMax;
        mMuteOut[channel] = mMuteIn[channel] = false;
    }

    const char *channelNameMap[NUM_CHANS+1] = {	kIOAudioControlChannelNameAll,
										kIOAudioControlChannelNameLeft,
										kIOAudioControlChannelNameRight,
										kIOAudioControlChannelNameCenter,
										kIOAudioControlChannelNameLeftRear,
										kIOAudioControlChannelNameRightRear,
										kIOAudioControlChannelNameSub };

    for (UInt32 channel=7; channel <= NUM_CHANS; channel++)
        channelNameMap[channel] = "Unknown Channel";

    for (unsigned channel=0; channel <= NUM_CHANS; channel++) {

        // Create an output volume control for each channel with an int range from 0 to 65535
        // and a db range from -72 to 0
        // Once each control is added to the audio engine, they should be released
        // so that when the audio engine is done with them, they get freed properly

		 // Volume level notes.
		 //
		 // Previously, the minimum volume was actually 10*log10(1/65535) = -48.2 dB. In the new
		 // scheme, we use a size 100 lookup table to compute the correct log scaling. And set
		 // the minimum to -40 dB. Perhaps -50 dB would have been better, but this seems ok.

        control = IOAudioLevelControl::createVolumeControl(WavTapDevice::kVolumeMax,		// Initial value
                                                           0,									// min value
                                                           WavTapDevice::kVolumeMax,		// max value
                                                           (-40 << 16) + (32768),				// -72 in IOFixed (16.16)
                                                           0,									// max 0.0 in IOFixed
                                                           channel,								// kIOAudioControlChannelIDDefaultLeft,
                                                           channelNameMap[channel],				// kIOAudioControlChannelNameLeft,
                                                           channel,								// control ID - driver-defined
                                                           kIOAudioControlUsageOutput);
        addControl(control, (IOAudioControl::IntValueChangeHandler)volumeChangeHandler);

        // Gain control for each channel
        control = IOAudioLevelControl::createVolumeControl(WavTapDevice::kGainMax,			// Initial value
                                                           0,									// min value
                                                           WavTapDevice::kGainMax,			// max value
                                                           0,									// min 0.0 in IOFixed
                                                           (40 << 16) + (32768),				// 72 in IOFixed (16.16)
                                                           channel,								// kIOAudioControlChannelIDDefaultLeft,
                                                           channelNameMap[channel],				// kIOAudioControlChannelNameLeft,
                                                           channel,								// control ID - driver-defined
                                                           kIOAudioControlUsageInput);
        addControl(control, (IOAudioControl::IntValueChangeHandler)gainChangeHandler);
    }

    // Create an output mute control
    control = IOAudioToggleControl::createMuteControl(false,									// initial state - unmuted
                                                      kIOAudioControlChannelIDAll,				// Affects all channels
                                                      kIOAudioControlChannelNameAll,
                                                      0,										// control ID - driver-defined
                                                      kIOAudioControlUsageOutput);
    addControl(control, (IOAudioControl::IntValueChangeHandler)outputMuteChangeHandler);

    // Create an input mute control
    control = IOAudioToggleControl::createMuteControl(false,									// initial state - unmuted
                                                      kIOAudioControlChannelIDAll,				// Affects all channels
                                                      kIOAudioControlChannelNameAll,
                                                      0,										// control ID - driver-defined
                                                      kIOAudioControlUsageInput);
    addControl(control, (IOAudioControl::IntValueChangeHandler)inputMuteChangeHandler);

    return true;
}


IOReturn WavTapDevice::volumeChangeHandler(IOService *target, IOAudioControl *volumeControl, SInt32 oldValue, SInt32 newValue)
{
    IOReturn			result = kIOReturnBadArgument;
    WavTapDevice*	audioDevice = (WavTapDevice *)target;

    if (audioDevice)
        result = audioDevice->volumeChanged(volumeControl, oldValue, newValue);
    return result;
}


IOReturn WavTapDevice::volumeChanged(IOAudioControl *volumeControl, SInt32 oldValue, SInt32 newValue)
{
    if (volumeControl)
         mVolume[volumeControl->getChannelID()] = newValue;
    return kIOReturnSuccess;
}


IOReturn WavTapDevice::outputMuteChangeHandler(IOService *target, IOAudioControl *muteControl, SInt32 oldValue, SInt32 newValue)
{
    IOReturn			result = kIOReturnBadArgument;
    WavTapDevice*	audioDevice = (WavTapDevice*)target;

    if (audioDevice)
        result = audioDevice->outputMuteChanged(muteControl, oldValue, newValue);
    return result;
}


IOReturn WavTapDevice::outputMuteChanged(IOAudioControl *muteControl, SInt32 oldValue, SInt32 newValue)
{
    if (muteControl)
         mMuteOut[muteControl->getChannelID()] = newValue;
    return kIOReturnSuccess;
}


IOReturn WavTapDevice::gainChangeHandler(IOService *target, IOAudioControl *gainControl, SInt32 oldValue, SInt32 newValue)
{
    IOReturn			result = kIOReturnBadArgument;
    WavTapDevice*	audioDevice = (WavTapDevice *)target;

    if (audioDevice)
        result = audioDevice->gainChanged(gainControl, oldValue, newValue);
    return result;
}


IOReturn WavTapDevice::gainChanged(IOAudioControl *gainControl, SInt32 oldValue, SInt32 newValue)
{
    if (gainControl)
		mGain[gainControl->getChannelID()] = newValue;
    return kIOReturnSuccess;
}


IOReturn WavTapDevice::inputMuteChangeHandler(IOService *target, IOAudioControl *muteControl, SInt32 oldValue, SInt32 newValue)
{
    IOReturn			result = kIOReturnBadArgument;
    WavTapDevice*	audioDevice = (WavTapDevice*)target;

    if (audioDevice)
        result = audioDevice->inputMuteChanged(muteControl, oldValue, newValue);
    return result;
}


IOReturn WavTapDevice::inputMuteChanged(IOAudioControl *muteControl, SInt32 oldValue, SInt32 newValue)
{
    if (muteControl)
         mMuteIn[muteControl->getChannelID()] = newValue;
    return kIOReturnSuccess;
}
