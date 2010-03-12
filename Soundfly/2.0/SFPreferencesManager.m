//
//  SFPreferencesManager.m
//  Soundfly
//
//  Created by JuL on 11/08/05.
//  Copyright 2005 abyssoft. All rights reserved.
//

#import "SFPreferencesManager.h"

#import <AudioUnit/AudioUnit.h>

#define SOUNDFLY_CONNECTION_NAME @"soundfly"
#define DEFAULT_NAME @"Soundfly"

NSString * SFDefaultsWillChangeNotification = @"SFDefaultsWillChangeNotification";
NSString * SFDefaultsDidChangeNotification = @"SFDefaultsDidChangeNotification";
NSString * SFDefaultsChangeNotification = @"SFDefaultsChangeNotification";

static SFPreferencesManager * _sharedPreferencesManager = nil;

@interface NSUserDefaults (Private)

+ (void)setStandardUserDefaults:(NSUserDefaults *)sud;

@end

@implementation NSObject (PreferencesAdditions)

- (void)bind:(NSString*)binding toPref:(NSString*)prefKey
{
	[self bind:binding toObject:[SFPreferencesManager sharedPreferencesManager] withKeyPath:prefKey options:nil];
}

@end

@interface SFPreferencesManager (Private)

- (NSUserDefaultsController*)_defaultsController;

@end

@implementation NSString (PreferencesAdditions)

- (BOOL)boolValue
{
	NSString * lowercaseString = [self lowercaseString];
	return [lowercaseString isEqualToString:@"yes"] || [lowercaseString isEqualToString:@"true"] || [lowercaseString isEqualToString:@"1"];
}

@end

@implementation SFPreferencesManager

+ (SFPreferencesManager*)sharedPreferencesManager
{
	if(_sharedPreferencesManager == nil)
		_sharedPreferencesManager = [[SFPreferencesManager alloc] init];
	return _sharedPreferencesManager;
}

- init
{
	self = [super init];
	
	NSString * appDomainName = [[NSBundle mainBundle] bundleIdentifier];
	NSString * domainName = [[NSBundle bundleForClass:[self class]] bundleIdentifier];
	_isLocal = [domainName isEqualToString:appDomainName];
	
	if(_isLocal) {
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(changeDefault:) name:SFDefaultsChangeNotification object:nil];
	}
	else {
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultsWillChange:) name:SFDefaultsWillChangeNotification object:nil];
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultsDidChange:) name:SFDefaultsDidChangeNotification object:nil];
	}
	
	return self;
}

- (void)dealloc
{
	if(_isLocal) {
		[[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:SFDefaultsChangeNotification object:nil];
	}
	else {
		[[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:SFDefaultsWillChangeNotification object:nil];
		[[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:SFDefaultsDidChangeNotification object:nil];
	}
	[super dealloc];
}

- (BOOL)isLocal
{
	return _isLocal;
}

- (NSString*)daemonConnectionName
{
	NSString * version = nil;
	
	if(_isLocal) {
		version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
	}
	else {
		NSBundle * mainBundle = [NSBundle bundleForClass:[self class]];
		NSString * daemonPath = [mainBundle pathForResource:SOUNDFLY_DAEMON ofType:@"app"];
		NSBundle * daemonBundle = [NSBundle bundleWithPath:daemonPath];
		NSDictionary * daemonInfoDict = [daemonBundle infoDictionary];
		version = [daemonInfoDict objectForKey:@"CFBundleVersion"];
	}
	
	return [NSString stringWithFormat:@"%@-%@", SOUNDFLY_CONNECTION_NAME, version];
}

- (NSUserDefaultsController*)_defaultsController
{
	static NSUserDefaultsController * _userDefaultsController = nil;
	
	if(_userDefaultsController == nil) {
		NSString * appDomainName = [[NSBundle mainBundle] bundleIdentifier];
		NSString * domainName = [[NSBundle bundleForClass:[self class]] bundleIdentifier];
		NSUserDefaults * defaults = [[NSUserDefaults alloc] init];
		[defaults removeSuiteNamed:appDomainName];
		[defaults addSuiteNamed:domainName];
		
		_userDefaultsController = [[NSUserDefaultsController alloc] initWithDefaults:defaults initialValues:nil];
        
		[_userDefaultsController setInitialValues:[NSDictionary dictionaryWithObjectsAndKeys:
                                                   [NSNumber numberWithBool:YES], SHOW_STATUS_ITEM,
                                                   
                                                   [NSNumber numberWithBool:NO], RECEIVER_ACTIVE,
                                                   DEFAULT_NAME, RECEIVER_NAME,
                                                   
                                                   [NSNumber numberWithBool:NO], SENDER_ACTIVE,
                                                   [NSNumber numberWithInt:52800], SENDER_PORT,
                                                   [NSNumber numberWithInt:kAUNetSendPresetFormat_Lossless16], SENDER_FORMAT_TAG,
                                                   DEFAULT_NAME, SENDER_CURRENT_NAME,
                                                   [NSArray arrayWithObject:DEFAULT_NAME], SENDER_KNOWN_NAMES,
												   nil]];
		
		[defaults release];
	}
	
	return _userDefaultsController;
}

- (id)valueForKey:(NSString*)key
{
	return [[self _defaultsController] valueForKeyPath:[NSString stringWithFormat:@"values.%@", key]];
}

- (BOOL)boolForPref:(NSString*)pref
{
	return [[self valueForKey:pref] boolValue];
}

- (int)intForPref:(NSString*)pref
{
	return [[self valueForKey:pref] intValue];
}

- (float)floatForPref:(NSString*)pref
{
	return [[self valueForKey:pref] floatValue];
}

- (id)valueForPref:(NSString*)pref
{
	return [self valueForKey:pref];
}

- (void)addObserver:(NSObject*)observer forPref:(NSString*)pref
{
    NSUserDefaultsController * defaultsController = [self _defaultsController];
    [defaultsController addObserver:observer forKeyPath:[NSString stringWithFormat:@"values.%@", pref] options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)removeObserver:(NSObject*)observer forPref:(NSString*)pref
{
    NSUserDefaultsController * defaultsController = [self _defaultsController];
    [defaultsController removeObserver:observer forKeyPath:[NSString stringWithFormat:@"values.%@", pref]];
}

- (void)setValue:(id)value forKey:(NSString*)key
{
	if(_isLocal) {
		NSUserDefaultsController * defaultsController = [self _defaultsController];
		[self willChangeValueForKey:key];
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:SFDefaultsWillChangeNotification object:key];
		[defaultsController setValue:value forKeyPath:[NSString stringWithFormat:@"values.%@", key]];
		[[defaultsController defaults] synchronize];
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:SFDefaultsDidChangeNotification object:key];
		[self didChangeValueForKey:key];
	}
	else {
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:SFDefaultsChangeNotification object:key userInfo:[NSDictionary dictionaryWithObject:value forKey:key]];
	}
}

- (void)changeDefault:(NSNotification*)notification
{
	NSString * key = [notification object];
	id value = [[notification userInfo] objectForKey:key];
	[self setValue:value forKeyPath:key];
}

- (void)defaultsWillChange:(NSNotification*)notification
{
	NSString * keyPath = [notification object];
	[self willChangeValueForKey:keyPath];
}

- (void)defaultsDidChange:(NSNotification*)notification
{
	NSString * keyPath = [notification object];
	[[[self _defaultsController] defaults] synchronize];
	[self didChangeValueForKey:keyPath];
}

static NSString *const kFSBonjourNameFormat = @"\t%@\tlocal.";

- (NSString*)bonjourNameFromSpeakerName:(NSString*)speakerName
{
    return [NSString stringWithFormat:kFSBonjourNameFormat, speakerName];
}

@end
