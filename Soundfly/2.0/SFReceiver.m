//
//  SFReceiver.m
//  Soundfly
//
//  Created by JuL on 20/02/07.
//  Copyright 2007 abyssoft. All rights reserved.
//

#import "SFReceiver.h"

#import "SFPreferencesManager.h"

static CFStringRef const kSFBonjourHostnameFormat = CFSTR("\t%@\tlocal.");

@interface SFReceiver (Internal)

- (OSStatus)_setupAudioUnits;
- (OSStatus)_startListen;

@end

@implementation SFReceiver

- (void)activate
{
    NSLog(@"activate receiver");
        
    OSStatus err;
    err = [self _setupAudioUnits];
    
    if(err == noErr) {
        err = [self _startListen];
        if(err == noErr) {
            //NSLog(@"All OK, waiting for audio stream...");
        }
    }
    
    [[SFPreferencesManager sharedPreferencesManager] addObserver:self forPref:RECEIVER_NAME];
    [[SFPreferencesManager sharedPreferencesManager] addObserver:self forPref:RECEIVER_PASSWORD];
    
    [super activate];
}

- (void)deactivate
{
    NSLog(@"deactivate receiver");
    
    [super deactivate];
    
    [[SFPreferencesManager sharedPreferencesManager] removeObserver:self forPref:RECEIVER_NAME];
    [[SFPreferencesManager sharedPreferencesManager] removeObserver:self forPref:RECEIVER_PASSWORD];
}

- (AudioUnit)audioUnit
{
    return _netReceiveUnit;
}

- (NSString*)moduleID
{
    return kSFModuleReceiverID;
}
    
- (OSStatus)_setupAudioUnits
{
	UInt32 size;
	
	// Get output device
	size = sizeof(_outputDeviceID);
	CHECK_ERR(AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice, &size, &_outputDeviceID), @"Couldn't get default output device");
	
	AUNode outputNode, netReceiveNode;
	
	NewAUGraph(&_graph);
	
	CHECK_ERR(AUGraphOpen(_graph), @"Couldn't open graph");
	CHECK_ERR(AUGraphInitialize(_graph), @"Couldn't initialize graph");
	
	// Setup output component
	ComponentDescription outputComponent;
	outputComponent.componentType = kAudioUnitType_Output;
	outputComponent.componentSubType = kAudioUnitSubType_HALOutput;
	outputComponent.componentManufacturer = kAudioUnitManufacturer_Apple;
	outputComponent.componentFlags = 0;
	outputComponent.componentFlagsMask = 0;
	
	CHECK_ERR(AUGraphAddNode(_graph, &outputComponent, &outputNode), @"Couldn't initialize output unit");
	CHECK_ERR(AUGraphNodeInfo(_graph, outputNode, NULL, &_outputUnit), @"Couldn't AUGraphGetNodeInfo");
	
	// Setup netReceive component
	ComponentDescription netReceiveComponent;
	netReceiveComponent.componentType = kAudioUnitType_Generator;
	netReceiveComponent.componentSubType = kAudioUnitSubType_NetReceive;
	netReceiveComponent.componentManufacturer = kAudioUnitManufacturer_Apple;
	netReceiveComponent.componentFlags = 0;
	netReceiveComponent.componentFlagsMask = 0;
	
	CHECK_ERR(AUGraphAddNode(_graph, &netReceiveComponent, &netReceiveNode), @"Couldn't AUGraphNewNode");
	CHECK_ERR(AUGraphNodeInfo(_graph, netReceiveNode, NULL, &_netReceiveUnit), @"Couldn't AUGraphGetNodeInfo");
    
    NSString * speakerName = [[SFPreferencesManager sharedPreferencesManager] valueForPref:RECEIVER_NAME];
    CFStringRef hostname = (CFStringRef)[[SFPreferencesManager sharedPreferencesManager] bonjourNameFromSpeakerName:speakerName];    
	CHECK_ERR(AudioUnitSetProperty(_netReceiveUnit,
                                   kAUNetReceiveProperty_Hostname,
                                   kAudioUnitScope_Global,
                                   0,
                                   &hostname,
                                   sizeof(hostname)), @"AudioUnitSetProperty");
    
    UInt32 flag = 0;
    CHECK_ERR(AudioUnitSetProperty(_netReceiveUnit,
								   kAUNetSendProperty_Disconnect,
								   kAudioUnitScope_Global,
								   0,
								   &flag,
								   sizeof(UInt32)), @"Couldn't set MakeConnection property");
	
	// Set IO
    flag = 0;
	CHECK_ERR(AudioUnitSetProperty(_outputUnit,
								   kAudioOutputUnitProperty_EnableIO,
								   kAudioUnitScope_Input,
								   1,
								   &flag,
								   sizeof(UInt32)), @"Couldn't set EnableIO/output property");
	
	flag = 1;
	CHECK_ERR(AudioUnitSetProperty(_outputUnit,
								   kAudioOutputUnitProperty_EnableIO,
								   kAudioUnitScope_Output,
								   0,
								   &flag,
								   sizeof(UInt32)), @"Couldn't set EnableIO/Output property");
	
	CHECK_ERR(AudioUnitSetProperty(_outputUnit,
								   kAudioOutputUnitProperty_CurrentDevice,
								   kAudioUnitScope_Global,
								   0,
								   &_outputDeviceID,
								   sizeof(UInt32)), @"Couldn't set EnableIO/CurrentDevice property");

	CHECK_ERR(AUGraphConnectNodeInput(_graph, netReceiveNode, 0, outputNode, 0), @"Couldn't AUGraphConnectNodeoutput");
	CHECK_ERR(AUGraphUpdate(_graph, NULL), @"Couldn't AUGraphUpdate");
	CHECK_ERR(AUGraphInitialize(_graph), @"Couldn't AUGraphInitialize");
	
	return noErr;
}

- (OSStatus)_startListen
{
	CHECK_ERR(AUGraphStart(_graph), @"Couldn't start graph");
	return noErr;
}

@end
