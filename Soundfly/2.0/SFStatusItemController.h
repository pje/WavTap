//
//  TPStatusItemController.h
//  Soundfly
//
//  Created by JuL on 20/05/05.
//  Copyright 2005 abyssoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SFStatusItemController : NSObject
{
	NSStatusItem * _statusItem;
    id _delegate;
}

+ (SFStatusItemController*)defaultController;

- (void)setDelegate:(id)delegate;

- (void)setShowStatusItem:(BOOL)showStatusItem;
- (BOOL)showStatusItem;

- (void)setStreaming:(BOOL)streaming;

@end

@interface NSObject (SFStatusItemDelegate)

- (void)resetLag;

@end

