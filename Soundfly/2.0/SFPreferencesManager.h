//
//  SFPreferencesManager.h
//  Soundfly
//
//  Created by JuL on 11/08/05.
//  Copyright 2005 abyssoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define SOUNDFLY_DAEMON @"soundflyd"

#define SHOW_STATUS_ITEM @"showStatusItem"

#define RECEIVER_ACTIVE @"receiverActive"
#define RECEIVER_NAME @"receiverName"
#define RECEIVER_PASSWORD @"receiverPassword"

#define SENDER_ACTIVE @"senderActive"
#define SENDER_PORT @"senderPort"
#define SENDER_FORMAT_TAG @"senderFormatTag"
#define SENDER_CURRENT_NAME @"senderCurrentName"
#define SENDER_KNOWN_NAMES @"senderKnownNames"

extern NSString * SFDefaultsDidChangeNotification;

@interface NSObject (PreferencesAdditions)

- (void)bind:(NSString*)binding toPref:(NSString*)prefKey;

@end

@interface SFPreferencesManager : NSObject
{
	BOOL _isLocal;
}

+ (SFPreferencesManager*)sharedPreferencesManager;

- (BOOL)isLocal;
- (NSString*)daemonConnectionName;

- (BOOL)boolForPref:(NSString*)pref;
- (int)intForPref:(NSString*)pref;
- (float)floatForPref:(NSString*)pref;
- (id)valueForPref:(NSString*)pref;

- (void)addObserver:(NSObject*)observer forPref:(NSString*)pref;
- (void)removeObserver:(NSObject*)observer forPref:(NSString*)pref;

- (NSString*)bonjourNameFromSpeakerName:(NSString*)speakerName;

@end
