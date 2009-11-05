//
//  SFAUModule.h
//  Soundfly
//
//  Created by Julien Robert on 16/02/08.
//  Copyright 2008 abyssoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreAudio/CoreAudio.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AUCocoaUIView.h>

#import "SFCommon.h"

#define CHECK_ERR(function, string) \
{ \
OSStatus err = function; \
if(err != noErr) { \
NSLog(@"%@: %d", string, err); \
return err; \
} \
}

#define CHECK_ERR_NORET(function, string) \
{ \
OSStatus err = function; \
if(err != noErr) { \
NSLog(@"%@: %d", string, err); \
return; \
} \
}

@interface SFAUModule : NSObject
{
	AUGraph _graph;
    AUEventListenerRef _eventListenerRef;
    
    id _delegate;
}

- (void)setDelegate:(id)delegate;

- (void)setActive:(BOOL)active;
- (BOOL)active;

- (void)activate;
- (void)deactivate;

- (int)status;

- (AudioUnit)audioUnit;
- (NSString*)moduleID;

@end

@interface NSObject (SFAUModuleDelegate)

- (void)moduleDidActivate:(SFAUModule*)module;
- (void)module:(SFAUModule*)module didChangeStatus:(int)status;

@end
