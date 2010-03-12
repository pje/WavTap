//
//  SFCommon.h
//  Soundfly
//
//  Created by JuL on 20/02/07.
//  Copyright 2007 abyssoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreAudio/CoreAudio.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>
#import <AudioUnit/AUCocoaUIView.h>
#import <Carbon/Carbon.h>

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

extern CFStringRef const kSFFirstTimeKey;
extern CFStringRef const kSFCleanExitKey;

extern CFStringRef const kSFBonjourNameKey;
extern CFStringRef const kSFDefaultBonjourName;

extern CFStringRef const kSFPortKey;
extern const UInt32 kSFDefaultPort;

extern CFStringRef const kSFPresetFormatKey;
extern const UInt32 kSFDefaultPresetFormat;

extern NSView * SFViewForUnit(AudioUnit unit);

extern Boolean SFPrefGetBoolValue(CFStringRef key, Boolean defaultValue);
extern void SFPrefSetBoolValue(CFStringRef key, Boolean value);

extern UInt32 SFPrefGetIntValue(CFStringRef key, UInt32 defaultValue);
extern void SFPrefSetIntValue(CFStringRef key, UInt32 value);

extern CFStringRef SFPrefCopyStringValue(CFStringRef key, CFStringRef defaultValue);
extern void SFPrefSetStringValue(CFStringRef key, CFStringRef value);

extern void SFPrefSynchronize();
