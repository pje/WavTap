//
//  SFCommon.m
//  Soundfly
//
//  Created by JuL on 20/02/07.
//  Copyright 2007 abyssoft. All rights reserved.
//

#import "SFCommon.h"

CFStringRef const kSFFirstTimeKey = CFSTR("FirstTime");
CFStringRef const kSFCleanExitKey = CFSTR("CleanExit");

CFStringRef const kSFBonjourNameKey = CFSTR("BonjourName");
CFStringRef const kSFDefaultBonjourName = CFSTR("Soundfly");

CFStringRef const kSFPortKey = CFSTR("Port");
const UInt32 kSFDefaultPort = 52800;

CFStringRef const kSFPresetFormatKey = CFSTR("PresetFormat");
const UInt32 kSFDefaultPresetFormat = kAUNetSendPresetFormat_Lossless16;

NSView * SFViewForUnit(AudioUnit unit)
{
    UInt32 dataSize;
    Boolean isWritable;
    AudioUnitCocoaViewInfo * cocoaViewInfo = NULL;
    UInt32 numberOfClasses;
    
    OSStatus result = AudioUnitGetPropertyInfo(unit, kAudioUnitProperty_CocoaUI, kAudioUnitScope_Global, 0, &dataSize, &isWritable);
    
    numberOfClasses = (dataSize - sizeof(CFURLRef)) / sizeof(CFStringRef);
    
    NSURL * CocoaViewBundlePath = nil;
    NSString * factoryClassName = nil;
    
    if((result == noErr) && (numberOfClasses > 0)) {
        cocoaViewInfo = (AudioUnitCocoaViewInfo *)malloc(dataSize);
        if(AudioUnitGetProperty(unit,
								kAudioUnitProperty_CocoaUI,
								kAudioUnitScope_Global,
								0,
								cocoaViewInfo,
								&dataSize) == noErr) {
            CocoaViewBundlePath	= (NSURL *)cocoaViewInfo->mCocoaAUViewBundleLocation;
            factoryClassName = (NSString *)cocoaViewInfo->mCocoaAUViewClass[0];
        }
		else {
            if(cocoaViewInfo != NULL) {
				free(cocoaViewInfo);
				cocoaViewInfo = NULL;
			}
        }
    }
	
	NSView * unitView = nil;
	
	if(CocoaViewBundlePath && factoryClassName) {
		NSBundle * viewBundle = [NSBundle bundleWithPath:[CocoaViewBundlePath path]];
		if(viewBundle == nil) {
			NSLog(@"Error loading AU view's bundle");
			return nil;
		}
		
		Class factoryClass = [viewBundle classNamed:factoryClassName];
		if(factoryClass == Nil) {
            NSLog(@"Error getting AU view's factory class from bundle");
            return nil;
        }
		
		id factoryInstance = [[factoryClass alloc] init];
		unitView = [factoryInstance uiViewForAudioUnit:unit withSize:NSZeroSize];
		[CocoaViewBundlePath release];
		[factoryInstance release];
		
		if(cocoaViewInfo) {
			UInt32 i;
			for(i = 0; i < numberOfClasses; i++)
				CFRelease(cocoaViewInfo->mCocoaAUViewClass[i]);
			
			free(cocoaViewInfo);
		}
	}
	
	return unitView;
}

Boolean SFPrefGetBoolValue(CFStringRef key, Boolean defaultValue)
{
    Boolean value = defaultValue;
    Boolean prefExists = false;
    value = CFPreferencesGetAppBooleanValue(key, kCFPreferencesCurrentApplication, &prefExists);
    if(!prefExists) {
        value = defaultValue;
    }
    
    return value;
}

void SFPrefSetBoolValue(CFStringRef key, Boolean value)
{
    CFPreferencesSetAppValue(key, value ? kCFBooleanTrue : kCFBooleanFalse, kCFPreferencesCurrentApplication);
}

UInt32 SFPrefGetIntValue(CFStringRef key, UInt32 defaultValue)
{
    UInt32 value = defaultValue;
    Boolean prefExists = false;
    value = CFPreferencesGetAppIntegerValue(key, kCFPreferencesCurrentApplication, &prefExists);
    if(!prefExists) {
        value = defaultValue;
    }
    
    return value;
}

void SFPrefSetIntValue(CFStringRef key, UInt32 value)
{
    CFNumberRef numberRef = CFNumberCreate(NULL, kCFNumberSInt32Type, &value);
    CFPreferencesSetAppValue(key, numberRef, kCFPreferencesCurrentApplication);
    CFRelease(numberRef);
}

CFStringRef SFPrefCopyStringValue(CFStringRef key, CFStringRef defaultValue)
{
    CFStringRef value = CFPreferencesCopyAppValue(key, kCFPreferencesCurrentApplication);
    if(value == NULL && defaultValue != NULL) {
        value = CFRetain(defaultValue);
    }
    
    return value;
}

void SFPrefSetStringValue(CFStringRef key, CFStringRef value)
{
    CFPreferencesSetAppValue(key, value, kCFPreferencesCurrentApplication);
}

void SFPrefSynchronize()
{
    CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication);
}
