//
//  SFSender.m
//  Soundfly
//
//  Created by JuL on 11/02/07.
//  Copyright 2007 abyssoft. All rights reserved.
//

#import "SFSender.h"

static CFStringRef const kSFSystemDeviceUID = CFSTR("AppleHDAEngineOutput:0");
static CFStringRef const kSFSoundflowerDeviceUID = CFSTR("SoundflowerEngine:0");

@interface SFSender (Internal)

- (OSStatus)_setupAudioUnits;
- (OSStatus)_startStream;
- (OSStatus)_setSoundflowerOutput;

@end

@implementation SFSender

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	OSStatus err;
	err = [self _setupAudioUnits];
	
	if(err == noErr) {
		UInt32 modifiers = GetCurrentKeyModifiers();
		BOOL showControls = ((modifiers & optionKey) != 0);
        
        if(SFPrefGetBoolValue(kSFFirstTimeKey, true)) {
            int retValue = NSRunAlertPanel(@"Welcome to Soundfly.", @"You are now ready to stream the audio.\nYou can customize the compression format and other settings in the preferences.", @"Start streaming", @"Show preferences", nil);
            
            if(retValue == NSAlertAlternateReturn) {
                showControls = YES;
            }
            
            SFPrefSetBoolValue(kSFFirstTimeKey, false);
        }
		
		if(showControls) {
            [self showOptions:nil];
		}
		
		err = [self _setSoundflowerOutput];
		if(err == noErr) {
			err = [self _startStream];
		}
		
		if(err == noErr) {
			//NSLog(@"All OK, streaming audio content...");
			if(!showControls) {
				[NSApp hide:nil];
			}
		}
	}
	else if(err == -2) {
		NSRunAlertPanel(@"Soundflower not installed.", @"You need to have Soundflower installed in order to use Soundfly. Please re-install from the package.", @"OK", nil, nil);
		[NSApp terminate:nil];
	}
}

- (OSStatus)_setupAudioUnits
{
	UInt32 size;
	
	// Save current output device
	size = sizeof(_outputDeviceID);
	CHECK_ERR(AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice, &size, &_outputDeviceID), @"Couldn't get default output device");
    
	// Get devices
	CHECK_ERR(AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDevices, &size, NULL), @"Couldn't get devices info");
	
	AudioDeviceID deviceIDs[size];
    CHECK_ERR(AudioHardwareGetProperty(kAudioHardwarePropertyDevices, &size, &deviceIDs), @"Couldn't get devices");
	
	// Get Soundflower device
	_soundflowerDeviceID = -1;
	int i = 0;
	while(i < size && _soundflowerDeviceID == -1) {
		AudioDeviceID deviceID = deviceIDs[i];
		
		CFStringRef uid;
		UInt32 stringSize = sizeof(uid);
		if(AudioDeviceGetProperty(deviceID, 0, false, kAudioDevicePropertyDeviceUID, &stringSize, &uid) == noErr) {
			if(CFEqual(uid, kSFSoundflowerDeviceUID)) {
				_soundflowerDeviceID = deviceID;
			}
			
			CFRelease(uid);
		}
		
		i++;
	}
	
	if(_soundflowerDeviceID == -1) {
		return -2;
	}
    
    // If the previous output was Soundflower and we crashed, try to find the system output because it usually means we crashed
    if((_outputDeviceID == _soundflowerDeviceID) && !SFPrefGetBoolValue(kSFCleanExitKey, true)) {
        i = 0;
        while(i < size && _outputDeviceID == _soundflowerDeviceID) {
            AudioDeviceID deviceID = deviceIDs[i];
            
            CFStringRef uid;
            UInt32 stringSize = sizeof(uid);
            if(AudioDeviceGetProperty(deviceID, 0, false, kAudioDevicePropertyDeviceUID, &stringSize, &uid) == noErr) {
                if(CFEqual(uid, kSFSystemDeviceUID)) {
                    _outputDeviceID = deviceID;
                }
                
                CFRelease(uid);
            }
            
            i++;
        }        
    }
    
    // Set pref for clean exit
    SFPrefSetBoolValue(kSFCleanExitKey, false);
    SFPrefSynchronize();
	
	AUNode inputNode, netSendNode, mixerNode;
	
	NewAUGraph(&_graph);
	
	CHECK_ERR(AUGraphOpen(_graph), @"Couldn't open graph");
	CHECK_ERR(AUGraphInitialize(_graph), @"Couldn't initialize graph");
	
	// Setup input component
	ComponentDescription inputComponent;
	inputComponent.componentType = kAudioUnitType_Output;
	inputComponent.componentSubType = kAudioUnitSubType_HALOutput;
	inputComponent.componentManufacturer = kAudioUnitManufacturer_Apple;
	inputComponent.componentFlags = 0;
	inputComponent.componentFlagsMask = 0;
	
	CHECK_ERR(AUGraphAddNode(_graph, &inputComponent, &inputNode), @"Couldn't initialize input unit");
	CHECK_ERR(AUGraphNodeInfo(_graph, inputNode, NULL, &_inputUnit), @"Couldn't AUGraphGetNodeInfo");
	
	// Setup netSend component
	ComponentDescription netSendComponent;
	netSendComponent.componentType = kAudioUnitType_Effect;
	netSendComponent.componentSubType = kAudioUnitSubType_NetSend;
	netSendComponent.componentManufacturer = kAudioUnitManufacturer_Apple;
	netSendComponent.componentFlags = 0;
	netSendComponent.componentFlagsMask = 0;
	
	CHECK_ERR(AUGraphAddNode(_graph, &netSendComponent, &netSendNode), @"Couldn't AUGraphNewNode");
	CHECK_ERR(AUGraphNodeInfo(_graph, netSendNode, NULL, &_netSendUnit), @"Couldn't AUGraphGetNodeInfo");
	
	UInt32 presetFormat = SFPrefGetIntValue(kSFPresetFormatKey, kSFDefaultPresetFormat);
	CHECK_ERR(AudioUnitSetProperty(_netSendUnit,
                                   kAUNetSendProperty_TransmissionFormatIndex,
                                   kAudioUnitScope_Global,
                                   0,
                                   &presetFormat,
                                   sizeof(UInt32)), @"AudioUnitSetProperty");
    
    CFStringRef bonjourName = SFPrefCopyStringValue(kSFBonjourNameKey, kSFDefaultBonjourName);
	CHECK_ERR(AudioUnitSetProperty(_netSendUnit,
                                   kAUNetSendProperty_ServiceName,
                                   kAudioUnitScope_Global,
                                   0,
                                   &bonjourName,
                                   sizeof(bonjourName)), @"AudioUnitSetProperty");
    CFRelease(bonjourName);
    
    UInt32 port = SFPrefGetIntValue(kSFPortKey, kSFDefaultPort);
    CHECK_ERR(AudioUnitSetProperty(_netSendUnit,
								   kAUNetSendProperty_PortNum,
								   kAudioUnitScope_Global,
								   0,
								   &port,
								   sizeof(UInt32)), @"Couldn't set port");    
	
	// Setup mixer component
	ComponentDescription mixerComponent;
	mixerComponent.componentType = kAudioUnitType_Mixer;
	mixerComponent.componentSubType = kAudioUnitSubType_StereoMixer;
	mixerComponent.componentManufacturer = kAudioUnitManufacturer_Apple;
	mixerComponent.componentFlags = 0;
	mixerComponent.componentFlagsMask = 0;
	AudioUnit mixerUnit;
	
	CHECK_ERR(AUGraphAddNode(_graph, &mixerComponent, &mixerNode), @"Couldn't AUGraphNewNode");
	CHECK_ERR(AUGraphNodeInfo(_graph, mixerNode, NULL, &mixerUnit), @"Couldn't AUGraphGetNodeInfo");
	CHECK_ERR(AudioUnitSetParameter(mixerUnit, kStereoMixerParam_Volume, kAudioUnitScope_Output, 0, 0.0, 0), @"AudioUnitSetParameter");
	
	// Set IO
	UInt32 flag = 1;
	CHECK_ERR(AudioUnitSetProperty(_inputUnit,
								   kAudioOutputUnitProperty_EnableIO,
								   kAudioUnitScope_Input,
								   1,
								   &flag,
								   sizeof(UInt32)), @"Couldn't set EnableIO/Input property");
	
	CHECK_ERR(AudioUnitSetProperty(_inputUnit,
								   kAudioOutputUnitProperty_EnableIO,
								   kAudioUnitScope_Output,
								   0,
								   &flag,
								   sizeof(UInt32)), @"Couldn't set EnableIO/Output property");
	
	CHECK_ERR(AudioUnitSetProperty(_inputUnit,
								   kAudioOutputUnitProperty_CurrentDevice,
								   kAudioUnitScope_Global,
								   0,
								   &_soundflowerDeviceID,
								   sizeof(UInt32)), @"Couldn't set EnableIO/CurrentDevice property");
	
	// Set stream format
	AudioStreamBasicDescription format;
    size = sizeof(AudioStreamBasicDescription);
	
    CHECK_ERR(AudioUnitGetProperty(_netSendUnit,
								   kAudioUnitProperty_StreamFormat,
								   kAudioUnitScope_Input,
								   0,
								   &format,
								   &size), @"Couldn't get stream format");
	
    CHECK_ERR(AudioUnitSetProperty(_inputUnit,
								   kAudioUnitProperty_StreamFormat,
								   kAudioUnitScope_Output,
								   1,
								   &format,
								   sizeof(AudioStreamBasicDescription)), @"Couldn't set stream format");
    	
	CHECK_ERR(AUGraphConnectNodeInput(_graph, inputNode, 1, netSendNode, 0), @"Couldn't AUGraphConnectNodeInput");
	CHECK_ERR(AUGraphConnectNodeInput(_graph, netSendNode, 0, mixerNode, 0), @"Couldn't AUGraphConnectNodeInput");
	CHECK_ERR(AUGraphConnectNodeInput(_graph, mixerNode, 0, inputNode, 0), @"Couldn't AUGraphConnectNodeInput");
	CHECK_ERR(AUGraphUpdate(_graph, NULL), @"Couldn't AUGraphUpdate");
	CHECK_ERR(AUGraphInitialize(_graph), @"Couldn't AUGraphInitialize");
	
	return noErr;
}

- (OSStatus)_startStream
{
	CHECK_ERR(AUGraphStart(_graph), @"Couldn't start graph");
	return noErr;
}

- (OSStatus)_setSoundflowerOutput
{
	CHECK_ERR(AudioHardwareSetProperty(kAudioHardwarePropertyDefaultOutputDevice, sizeof(_soundflowerDeviceID), &_soundflowerDeviceID), @"Couldn't change default output device");
	return noErr;
}



- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    // Save prefs
    UInt32 port;
    UInt32 size = sizeof(UInt32);
    CHECK_ERR_NORET(AudioUnitGetProperty(_netSendUnit,
                                         kAUNetSendProperty_PortNum,
                                         kAudioUnitScope_Global,
                                         0,
                                         &port,
                                         &size), @"Couldn't get port");
    
    UInt32 format;
    CHECK_ERR_NORET(AudioUnitGetProperty(_netSendUnit,
                                         kAUNetSendProperty_TransmissionFormatIndex,
                                         kAudioUnitScope_Global,
                                         0,
                                         &format,
                                         &size), @"Couldn't get port");
    
    size = sizeof(CFStringRef);
    CFStringRef bonjourName;
    CHECK_ERR_NORET(AudioUnitGetProperty(_netSendUnit,
                                         kAUNetSendProperty_ServiceName,
                                         kAudioUnitScope_Global,
                                         0,
                                         &bonjourName,
                                         &size), @"Couldn't get bonjour name");
    
    SFPrefSetIntValue(kSFPortKey, port);
    SFPrefSetIntValue(kSFPresetFormatKey, format);
    SFPrefSetStringValue(kSFBonjourNameKey, bonjourName);
    SFPrefSetBoolValue(kSFCleanExitKey, true);
    CFRelease(bonjourName);    
    
    // Stop and release units
	AUGraphStop(_graph);
	AUGraphUninitialize(_graph);
	AUGraphClose(_graph);
	DisposeAUGraph(_graph);
	
	// Revert output device
	AudioHardwareSetProperty(kAudioHardwarePropertyDefaultOutputDevice, sizeof(_outputDeviceID), &_outputDeviceID);
}

- (IBAction)showOptions:(id)sender
{
    NSView * netSendView = SFViewForUnit(_netSendUnit);
    NSWindow * window = [[NSWindow alloc] initWithContentRect:[netSendView bounds] styleMask:NSTitledWindowMask|NSClosableWindowMask backing:NSBackingStoreBuffered defer:NO];
    [window setContentView:netSendView];
    [window center];
    [window setReleasedWhenClosed:YES];
    [window setTitle:@"Soundfly sender"];
    [window makeKeyAndOrderFront:nil];
    
}

@end
