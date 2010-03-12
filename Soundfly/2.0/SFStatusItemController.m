//
//  TPStatusItemController.m
//  Soundfly
//
//  Created by JuL on 20/05/05.
//  Copyright 2005 abyssoft. All rights reserved.
//

#import "SFStatusItemController.h"

#import "SFDaemonController.h"
#import "SFPreferencesManager.h"
#import "SFUtils.h"

static SFStatusItemController * _defaultController = nil;

@interface NSStatusItem (AppKitPrivate)

- (NSButton*)_button;

@end

@implementation SFStatusItemController

+ (SFStatusItemController*)defaultController
{
	if(_defaultController == nil)
		_defaultController = [[SFStatusItemController alloc] init];
	return _defaultController;
}

- init
{
	self = [super init];
	
	_statusItem = nil;
    
	return self;
}

- (void)dealloc
{
	[_statusItem release];
	[super dealloc];
}

- (void)setDelegate:(id)delegate
{
    _delegate = delegate;
}

- (void)_addMenuItemForPref:(NSString*)prefKey title:(NSString*)title toMenu:(NSMenu*)menu
{
    NSMenuItem * menuItem = [[NSMenuItem alloc] initWithTitle:title action:@selector(switchMenuItem:) keyEquivalent:@""];
    [menuItem setTarget:self];
    [menuItem setRepresentedObject:prefKey];
    [menuItem bind:@"state" toObject:[SFPreferencesManager sharedPreferencesManager] withKeyPath:prefKey options:nil];
    [menu addItem:menuItem];
    [menuItem release];
}

- (void)setShowStatusItem:(BOOL)showStatusItem
{
	if(showStatusItem && _statusItem == nil) {
		_statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
		[_statusItem retain];
		[_statusItem setHighlightMode:YES];
        
		[self setStreaming:NO];
		
		[[[_statusItem _button] cell] setFont:[NSFont systemFontOfSize:[NSFont systemFontSize]]];
		
		NSMenu * menu = [[NSMenu alloc] init];
		
        [self _addMenuItemForPref:SENDER_ACTIVE title:NSLocalizedString(@"Send audio", nil) toMenu:menu];
        
        NSMenuItem * resetLagMenuItem = [menu addItemWithTitle:NSLocalizedString(@"Reset lag", nil) action:@selector(resetLag) keyEquivalent:@""];
        [resetLagMenuItem bind:@"enabled" toObject:[SFPreferencesManager sharedPreferencesManager] withKeyPath:SENDER_ACTIVE options:nil];
		[resetLagMenuItem setTarget:_delegate];
        
        [menu addItem:[NSMenuItem separatorItem]];
        
        
        [self _addMenuItemForPref:RECEIVER_ACTIVE title:NSLocalizedString(@"Receive audio", nil) toMenu:menu];

		[menu addItem:[NSMenuItem separatorItem]];
		
		NSMenuItem * openPrefPanelMenuItem = [menu addItemWithTitle:NSLocalizedString(@"Configure\\U2026", nil) action:@selector(openSoundflyPanel) keyEquivalent:@""];
		[openPrefPanelMenuItem setTarget:self];
		
		[_statusItem setMenu:menu];
		[menu release];
	}
	else if(!showStatusItem && _statusItem != nil) {
		[[NSStatusBar systemStatusBar] removeStatusItem:_statusItem];
		[_statusItem release];
		_statusItem = nil;
	}
}

- (BOOL)showStatusItem
{
	return (_statusItem != nil);
}

- (void)setStreaming:(BOOL)streaming
{
    if(streaming) {
        [_statusItem setImage:[NSImage imageNamed:@"menuitem-on"]];
    }
    else {
        [_statusItem setImage:[NSImage imageNamed:@"menuitem-off"]];
    }
}

- (void)switchMenuItem:(id)sender
{
	[[SFPreferencesManager sharedPreferencesManager] setValue:[NSNumber numberWithBool:![sender state]] forKey:[sender representedObject]];
}

- (void)openSoundflyPanel
{
	[[NSWorkspace sharedWorkspace] showPreferencesPaneWithID:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"] async:YES];
}

@end
