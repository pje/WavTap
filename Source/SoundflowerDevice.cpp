/*
  File:SoundflowerDevice.cpp

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

/*
    Soundflower is derived from Apple's 'PhantomAudioDriver'
    sample code.  It uses the same timer mechanism to simulate a hardware
    interrupt, with some additional code to compensate for the software
    timer's inconsistencies.  
    
    Soundflower basically copies the mixbuffer and presents it to clients
    as an input buffer, allowing a applications to send audio one another.
*/

#include "SoundflowerDevice.h"

#include "SoundflowerEngine.h"

#include <IOKit/audio/IOAudioControl.h>
#include <IOKit/IOLib.h>

#define super IOAudioDevice

OSDefineMetaClassAndStructors(SoundflowerDevice, IOAudioDevice)

/*
 * initHardware()
 */

bool SoundflowerDevice::initHardware(IOService *provider)
{
    bool result = false;
    
  //  IOLog("SoundflowerDevice[%p]::initHardware(%p)\n", this, provider);
    
    if (!super::initHardware(provider)) {
        goto Done;
    }
    
    
    setDeviceName("Soundflower");
    setDeviceShortName("Soundflower");
    setManufacturerName("ma++ ingalls for Cycling '74");
    
    if (!createAudioEngines()) {
        goto Done;
    }
    
    result = true;
    
Done:

    return result;
}

/*
 * createAudioEngines()
 */

bool SoundflowerDevice::createAudioEngines()
{
    bool result = false;
    OSArray *audioEngineArray;
    
  //  IOLog("SoundflowerDevice[%p]::createAudioEngine()\n", this);
    
    audioEngineArray = OSDynamicCast(OSArray, getProperty(AUDIO_ENGINES_KEY));
    
    if (audioEngineArray) {
        OSCollectionIterator *audioEngineIterator;
        
        audioEngineIterator = OSCollectionIterator::withCollection(audioEngineArray);
        if (audioEngineIterator) {
            OSDictionary *audioEngineDict;
            
           while (audioEngineDict = (OSDictionary *)audioEngineIterator->getNextObject()) {
                if (OSDynamicCast(OSDictionary, audioEngineDict) != NULL) {
                    SoundflowerEngine *audioEngine;
                    
                    audioEngine = new SoundflowerEngine;
                    if (audioEngine) {
                        if (audioEngine->init(audioEngineDict)) {
                            activateAudioEngine(audioEngine);
                        }
                        audioEngine->release();
                    }
                }
            }
            
            audioEngineIterator->release();
        }
    } else {
    //    IOLog("SoundflowerDevice[%p]::createAudioEngine() - Error: no AudioEngine array in personality.\n", this);
        goto Done;
    }
    
    result = true;
    
Done:

    return result;
}

/*
 * volumeChangeHandler()
 */
 
IOReturn SoundflowerDevice::volumeChangeHandler(IOService *target, IOAudioControl *volumeControl, SInt32 oldValue, SInt32 newValue)
{
    IOReturn result = kIOReturnBadArgument;
    SoundflowerDevice *audioDevice;
    
    audioDevice = (SoundflowerDevice *)target;
    if (audioDevice) {
        result = audioDevice->volumeChanged(volumeControl, oldValue, newValue);
    }
    
    return result;
}

/*
 * volumeChanged()
 */
 
IOReturn SoundflowerDevice::volumeChanged(IOAudioControl *volumeControl, SInt32 oldValue, SInt32 newValue)
{
  //  IOLog("SoundflowerDevice[%p]::volumeChanged(%p, %ld, %ld)\n", this, volumeControl, oldValue, newValue);
    
    if (volumeControl) {
  //      IOLog("\t-> Channel %ld\n", volumeControl->getChannelID());
         mVolume[volumeControl->getChannelID()] = newValue;
    }

    return kIOReturnSuccess;
}

/*
 * outputMuteChangeHandler()
 */
 
IOReturn SoundflowerDevice::outputMuteChangeHandler(IOService *target, IOAudioControl *muteControl, SInt32 oldValue, SInt32 newValue)
{
    IOReturn result = kIOReturnBadArgument;
    SoundflowerDevice *audioDevice;
    
    audioDevice = (SoundflowerDevice *)target;
    if (audioDevice) {
        result = audioDevice->outputMuteChanged(muteControl, oldValue, newValue);
    }
    
    return result;
}

/*
 * outputMuteChanged()
 */
 
IOReturn SoundflowerDevice::outputMuteChanged(IOAudioControl *muteControl, SInt32 oldValue, SInt32 newValue)
{
  //  IOLog("SoundflowerDevice[%p]::outputMuteChanged(%p, %ld, %ld)\n", this, muteControl, oldValue, newValue);
    
    if (muteControl) {
       // IOLog("\t-> Channel %ld\n", muteControl->getChannelID());
         mMuteOut[muteControl->getChannelID()] = newValue;
    }
        
    return kIOReturnSuccess;
}

/*
 * gainChangeHandler()
 */
 
IOReturn SoundflowerDevice::gainChangeHandler(IOService *target, IOAudioControl *gainControl, SInt32 oldValue, SInt32 newValue)
{
    IOReturn result = kIOReturnBadArgument;
    SoundflowerDevice *audioDevice;
    
    audioDevice = (SoundflowerDevice *)target;
    if (audioDevice) {
        result = audioDevice->gainChanged(gainControl, oldValue, newValue);
    }
    
    return result;
}

/*
 * gainChanged()
 */
 
IOReturn SoundflowerDevice::gainChanged(IOAudioControl *gainControl, SInt32 oldValue, SInt32 newValue)
{
   // IOLog("SoundflowerDevice[%p]::gainChanged(%p, %ld, %ld)\n", this, gainControl, oldValue, newValue);
    
    if (gainControl) {
      //  IOLog("\t-> Channel %ld\n", gainControl->getChannelID());
         mGain[gainControl->getChannelID()] = newValue;
    }
    
    return kIOReturnSuccess;
}

/*
 * inputMuteChangeHandler()
 */
 
IOReturn SoundflowerDevice::inputMuteChangeHandler(IOService *target, IOAudioControl *muteControl, SInt32 oldValue, SInt32 newValue)
{
    IOReturn result = kIOReturnBadArgument;
    SoundflowerDevice *audioDevice;
    
    audioDevice = (SoundflowerDevice *)target;
    if (audioDevice) {
        result = audioDevice->inputMuteChanged(muteControl, oldValue, newValue);
    }
    
    return result;
}

/*
 * inputMuteChanged()
 */
 
IOReturn SoundflowerDevice::inputMuteChanged(IOAudioControl *muteControl, SInt32 oldValue, SInt32 newValue)
{
 //   IOLog("SoundflowerDevice[%p]::inputMuteChanged(%p, %ld, %ld)\n", this, muteControl, oldValue, newValue);
    
    if (muteControl) {
  //      IOLog("\t-> Channel %ld\n", muteControl->getChannelID());
         mMuteIn[muteControl->getChannelID()] = newValue;
    }
        
    return kIOReturnSuccess;
}
