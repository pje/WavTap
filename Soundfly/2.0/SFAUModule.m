//
//  SFAUModule.m
//  Soundfly
//
//  Created by Julien Robert on 16/02/08.
//  Copyright 2008 abyssoft. All rights reserved.
//

#import "SFAUModule.h"

#import "SFCommunicationManager.h"

@interface SFAUModule (Internal)

- (void)_parameter:(AudioUnitParameter)parameter didChangeToValue:(Float32)value;
- (void)_propertyDidChange:(AudioUnitProperty)property;

@end

void SFEventListenerProc(void * inCallbackRefCon, void * inObject, const AudioUnitEvent * inEvent, UInt64 inEventHostTime, Float32 inParameterValue)
{
    SFAUModule * module = (SFAUModule*)inCallbackRefCon;
    
    switch(inEvent->mEventType) {
        case kAudioUnitEvent_ParameterValueChange:
            [module _parameter:inEvent->mArgument.mParameter didChangeToValue:inParameterValue];
            break;
        case kAudioUnitEvent_PropertyChange:
            [module _propertyDidChange:inEvent->mArgument.mProperty];
            break;
    }
}

@implementation SFAUModule

- (void)setDelegate:(id)delegate
{
    _delegate = delegate;
}

- (BOOL)active
{
    return (_graph != NULL);
}

- (void)setActive:(BOOL)active
{
    if(active) {
        [self activate];
    }
    else {
        [self deactivate];
    }
}

- (void)activate
{
    CHECK_ERR_NORET(AUEventListenerCreate(SFEventListenerProc, self, CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0.2, 0.0, &_eventListenerRef), @"Can't add event listener");
    
    AudioUnitParameter statusParameter = {
        [self audioUnit],
        kAUNetSendParam_Status,
        kAudioUnitScope_Global,
        0
    };

    AudioUnitEvent statusEvent;
    statusEvent.mEventType = kAudioUnitEvent_ParameterValueChange;
    statusEvent.mArgument.mParameter = statusParameter;
    
    CHECK_ERR_NORET(AUEventListenerAddEventType(_eventListenerRef, NULL, &statusEvent), @"Can't add event type");
    
    AudioUnitProperty bonjourNameProperty = {
        [self audioUnit],
        kAUNetReceiveProperty_Hostname,
        kAudioUnitScope_Global,
        0
    };
    
    AudioUnitEvent bonjourNameEvent;
    bonjourNameEvent.mEventType = kAudioUnitEvent_PropertyChange;
    bonjourNameEvent.mArgument.mProperty = bonjourNameProperty;

    CHECK_ERR_NORET(AUEventListenerAddEventType(_eventListenerRef, NULL, &bonjourNameEvent), @"Can't add event type");
    
    if(_delegate != nil && [_delegate respondsToSelector:@selector(moduleDidActivate:)]) {
        [_delegate moduleDidActivate:self];
    }
}

- (void)deactivate
{
    // Stop and release units
    AUGraphStop(_graph);
    AUGraphUninitialize(_graph);
    AUGraphClose(_graph);
    DisposeAUGraph(_graph);
    _graph = NULL;
    
//    AUListenerDispose(_eventListenerRef);
}

- (int)status
{
    Float32 value;
    CHECK_ERR(AudioUnitGetParameter([self audioUnit], kAUNetReceiveParam_Status, kAudioUnitScope_Global, 0, &value), @"Can't get parameter");
    return (int)value;
}

- (AudioUnit)audioUnit
{
    return NULL;
}

- (NSString*)moduleID
{
    return nil;
}

- (void)_parameter:(AudioUnitParameter)parameter didChangeToValue:(Float32)value
{
    switch(parameter.mParameterID) {
        case kAUNetReceiveParam_Status:
            if(_delegate != nil && [_delegate respondsToSelector:@selector(module:didChangeStatus:)]) {
                [_delegate module:self didChangeStatus:(int)value];
            }
            break;
        default:
            break;
    }
}

- (void)_propertyDidChange:(AudioUnitProperty)property
{
    NSLog(@"property did change");
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self deactivate];
    [self activate];
}

@end
