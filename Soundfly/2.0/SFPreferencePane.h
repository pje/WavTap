//
//  SFPreferencePane.h
//  Soundfly
//
//  Created by Julien Robert on 15/02/08.
//  Copyright 2008 abyssoft. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>

@class SFVersionTextField;

@interface SFPreferencePane : NSPreferencePane
{
    BOOL _active;
    
    int _senderStatus;
    int _receiverStatus;
    
    IBOutlet NSWindow * _aboutWindow;
	IBOutlet SFVersionTextField * _versionTextField;
}

- (BOOL)isLeopardOrBetter;

- (IBAction)showAboutSheet:(id)sender;
- (void)closeAboutSheet;

- (NSImage*)receiverConnectionImage;
- (NSString*)receiverConnectionTooltip;

- (NSImage*)senderConnectionImage;
- (NSString*)senderConnectionTooltip;

@end
