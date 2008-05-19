/*	A "background" application that sits in the
	Finder's Menu Bar.  Mostly drived from apple's
	AudioThru example code, this allows users to tap
	into soundflower channels and route them to an
	output device.
*/


#import "Soundflowerbed.h"

@implementation Soundflowerbed

- (void)awakeFromNib
{
	NSStatusItem *sbItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
	[sbItem retain];
	//[sbItem setTitle:@"ее"];
	[sbItem setImage:[NSImage imageNamed:@"daisy"]];
	[sbItem setHighlightMode:YES];
	NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Nothing"];
	
	
	
	NSMenuItem *item = [menu addItemWithTitle:@"Output Device" action:NULL keyEquivalent:@""];
	[item setTarget:self];
	
	item = [menu addItemWithTitle:@"None (OFF)" action:@selector(doNothing) keyEquivalent:@""];
	[item setTarget:self];
	
	item = [menu addItemWithTitle:@"Built-in Audio" action:@selector(doNothing) keyEquivalent:@""];
	[item setTarget:self];

	item = [menu addItemWithTitle:@"Delta-410" action:@selector(doNothing) keyEquivalent:@""];
	[item setState:NSOnState];
	[item setTarget:self];	
	
	item = [menu addItemWithTitle:@"Emagic A26" action:@selector(doNothing) keyEquivalent:@""];
	[item setTarget:self];	
	
	[menu addItem:[NSMenuItem separatorItem]];
	
	
	item = [menu addItemWithTitle:@"Soundflower Device" action:NULL keyEquivalent:@""];
	[item setTarget:self];
	
	item = [menu addItemWithTitle:@"2 Channel" action:@selector(doNothing) keyEquivalent:@""];
	[item setTarget:self];

	item = [menu addItemWithTitle:@"16 Channel" action:@selector(doNothing) keyEquivalent:@""];
	[item setTarget:self];	
	[item setState:NSOnState];
	
	[menu addItem:[NSMenuItem separatorItem]];
	
	
	
	item = [menu addItemWithTitle:@"Soundflower Channel Routing" action:NULL keyEquivalent:@""];
	[item setTarget:self];
	
	item = [menu addItemWithTitle:@"1" action:@selector(doNothing) keyEquivalent:@""];
	[item setTarget:self];
	NSMenu *submenu = [[NSMenu alloc] initWithTitle:@"Nothing"];
	id subitem = [submenu addItemWithTitle:@"Delta-410 (1)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];	
	subitem = [submenu addItemWithTitle:@"Delta-410 (2)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];	
	subitem = [submenu addItemWithTitle:@"Delta-410 (3)" action:@selector(doNothing) keyEquivalent:@""];		[subitem setState:NSOnState];

	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (4)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (5)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (6)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (7)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (8)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	[item setSubmenu:submenu];
	
	item = [menu addItemWithTitle:@"2" action:@selector(doNothing) keyEquivalent:@""];
	[item setTarget:self];	
		submenu = [[NSMenu alloc] initWithTitle:@"Nothing"];
	subitem = [submenu addItemWithTitle:@"Delta-410 (1)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];	
	subitem = [submenu addItemWithTitle:@"Delta-410 (2)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];	
	subitem = [submenu addItemWithTitle:@"Delta-410 (3)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (4)" action:@selector(doNothing) keyEquivalent:@""];		[subitem setState:NSOnState];

	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (5)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (6)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (7)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (8)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	[item setSubmenu:submenu];
	
		item = [menu addItemWithTitle:@"3" action:@selector(doNothing) keyEquivalent:@""];
	[item setTarget:self];	
		submenu = [[NSMenu alloc] initWithTitle:@"Nothing"];
	subitem = [submenu addItemWithTitle:@"Delta-410 (1)" action:@selector(doNothing) keyEquivalent:@""];		[subitem setState:NSOnState];

	[subitem setTarget:self];	
	subitem = [submenu addItemWithTitle:@"Delta-410 (2)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];	
	subitem = [submenu addItemWithTitle:@"Delta-410 (3)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (4)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (5)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (6)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (7)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (8)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	[item setSubmenu:submenu];
	
		item = [menu addItemWithTitle:@"4" action:@selector(doNothing) keyEquivalent:@""];
	[item setTarget:self];	
			submenu = [[NSMenu alloc] initWithTitle:@"Nothing"];
	subitem = [submenu addItemWithTitle:@"Delta-410 (1)" action:@selector(doNothing) keyEquivalent:@""];		
	[subitem setTarget:self];	
	subitem = [submenu addItemWithTitle:@"Delta-410 (2)" action:@selector(doNothing) keyEquivalent:@""];[subitem setState:NSOnState];
	
	[subitem setTarget:self];	
	subitem = [submenu addItemWithTitle:@"Delta-410 (3)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (4)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (5)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (6)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (7)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (8)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	[item setSubmenu:submenu];
	
		item = [menu addItemWithTitle:@"5" action:@selector(doNothing) keyEquivalent:@""];
	[item setTarget:self];	
			submenu = [[NSMenu alloc] initWithTitle:@"Nothing"];
	subitem = [submenu addItemWithTitle:@"Delta-410 (1)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];	
	subitem = [submenu addItemWithTitle:@"Delta-410 (2)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];	
	subitem = [submenu addItemWithTitle:@"Delta-410 (3)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (4)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (5)" action:@selector(doNothing) keyEquivalent:@""];	[subitem setState:NSOnState];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (6)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (7)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (8)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	[item setSubmenu:submenu];
	
		item = [menu addItemWithTitle:@"6" action:@selector(doNothing) keyEquivalent:@""];
	[item setTarget:self];	
			submenu = [[NSMenu alloc] initWithTitle:@"Nothing"];
	subitem = [submenu addItemWithTitle:@"Delta-410 (1)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];	
	subitem = [submenu addItemWithTitle:@"Delta-410 (2)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];	
	subitem = [submenu addItemWithTitle:@"Delta-410 (3)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (4)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (5)" action:@selector(doNothing) keyEquivalent:@""];	

	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (6)" action:@selector(doNothing) keyEquivalent:@""];	[subitem setState:NSOnState];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (7)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (8)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	[item setSubmenu:submenu];
	
		item = [menu addItemWithTitle:@"7" action:@selector(doNothing) keyEquivalent:@""];
	[item setTarget:self];	
			submenu = [[NSMenu alloc] initWithTitle:@"Nothing"];
	subitem = [submenu addItemWithTitle:@"Delta-410 (1)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];	
	subitem = [submenu addItemWithTitle:@"Delta-410 (2)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];	
	subitem = [submenu addItemWithTitle:@"Delta-410 (3)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (4)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (5)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (6)" action:@selector(doNothing) keyEquivalent:@""];		

	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (7)" action:@selector(doNothing) keyEquivalent:@""];[subitem setState:NSOnState];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (8)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	[item setSubmenu:submenu];
	
		item = [menu addItemWithTitle:@"8" action:@selector(doNothing) keyEquivalent:@""];
	[item setTarget:self];	
			submenu = [[NSMenu alloc] initWithTitle:@"Nothing"];
	subitem = [submenu addItemWithTitle:@"Delta-410 (1)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];	
	subitem = [submenu addItemWithTitle:@"Delta-410 (2)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];	
	subitem = [submenu addItemWithTitle:@"Delta-410 (3)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (4)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (5)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (6)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (7)" action:@selector(doNothing) keyEquivalent:@""];	

	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (8)" action:@selector(doNothing) keyEquivalent:@""];	[subitem setState:NSOnState];
	[subitem setTarget:self];		
	[item setSubmenu:submenu];
	
		item = [menu addItemWithTitle:@"9" action:@selector(doNothing) keyEquivalent:@""];
	[item setTarget:self];	
			submenu = [[NSMenu alloc] initWithTitle:@"Nothing"];
	subitem = [submenu addItemWithTitle:@"Delta-410 (1)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];	
	subitem = [submenu addItemWithTitle:@"Delta-410 (2)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];	
	subitem = [submenu addItemWithTitle:@"Delta-410 (3)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (4)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (5)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (6)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (7)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (8)" action:@selector(doNothing) keyEquivalent:@""];		

	[subitem setTarget:self];		
	[item setSubmenu:submenu];
	
		item = [menu addItemWithTitle:@"10" action:@selector(doNothing) keyEquivalent:@""];
	[item setTarget:self];	
			submenu = [[NSMenu alloc] initWithTitle:@"Nothing"];
	subitem = [submenu addItemWithTitle:@"Delta-410 (1)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];	
	subitem = [submenu addItemWithTitle:@"Delta-410 (2)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];	
	subitem = [submenu addItemWithTitle:@"Delta-410 (3)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (4)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (5)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (6)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (7)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (8)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	[item setSubmenu:submenu];
	
		item = [menu addItemWithTitle:@"11" action:@selector(doNothing) keyEquivalent:@""];
	[item setTarget:self];	
			submenu = [[NSMenu alloc] initWithTitle:@"Nothing"];
	subitem = [submenu addItemWithTitle:@"Delta-410 (1)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];	
	subitem = [submenu addItemWithTitle:@"Delta-410 (2)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];	
	subitem = [submenu addItemWithTitle:@"Delta-410 (3)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (4)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (5)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (6)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (7)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (8)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	[item setSubmenu:submenu];
	
		item = [menu addItemWithTitle:@"12" action:@selector(doNothing) keyEquivalent:@""];
	[item setTarget:self];	
			submenu = [[NSMenu alloc] initWithTitle:@"Nothing"];
	subitem = [submenu addItemWithTitle:@"Delta-410 (1)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];	
	subitem = [submenu addItemWithTitle:@"Delta-410 (2)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];	
	subitem = [submenu addItemWithTitle:@"Delta-410 (3)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (4)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (5)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (6)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (7)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (8)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	[item setSubmenu:submenu];
	
		item = [menu addItemWithTitle:@"13" action:@selector(doNothing) keyEquivalent:@""];
	[item setTarget:self];	
			submenu = [[NSMenu alloc] initWithTitle:@"Nothing"];
	subitem = [submenu addItemWithTitle:@"Delta-410 (1)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];	
	subitem = [submenu addItemWithTitle:@"Delta-410 (2)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];	
	subitem = [submenu addItemWithTitle:@"Delta-410 (3)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (4)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (5)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (6)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (7)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (8)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	[item setSubmenu:submenu];
	
		item = [menu addItemWithTitle:@"14" action:@selector(doNothing) keyEquivalent:@""];
	[item setTarget:self];	
			submenu = [[NSMenu alloc] initWithTitle:@"Nothing"];
	subitem = [submenu addItemWithTitle:@"Delta-410 (1)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];	
	subitem = [submenu addItemWithTitle:@"Delta-410 (2)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];	
	subitem = [submenu addItemWithTitle:@"Delta-410 (3)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (4)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (5)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (6)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (7)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (8)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	[item setSubmenu:submenu];
	
		item = [menu addItemWithTitle:@"15" action:@selector(doNothing) keyEquivalent:@""];
	[item setTarget:self];	
			submenu = [[NSMenu alloc] initWithTitle:@"Nothing"];
	subitem = [submenu addItemWithTitle:@"Delta-410 (1)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];	
	subitem = [submenu addItemWithTitle:@"Delta-410 (2)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];	
	subitem = [submenu addItemWithTitle:@"Delta-410 (3)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (4)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (5)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (6)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (7)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (8)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	[item setSubmenu:submenu];
	
		item = [menu addItemWithTitle:@"16" action:@selector(doNothing) keyEquivalent:@""];
	[item setTarget:self];	
			submenu = [[NSMenu alloc] initWithTitle:@"Nothing"];
	subitem = [submenu addItemWithTitle:@"Delta-410 (1)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];	
	subitem = [submenu addItemWithTitle:@"Delta-410 (2)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];	
	subitem = [submenu addItemWithTitle:@"Delta-410 (3)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (4)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (5)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (6)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (7)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	subitem = [submenu addItemWithTitle:@"Delta-410 (8)" action:@selector(doNothing) keyEquivalent:@""];
	[subitem setTarget:self];		
	[item setSubmenu:submenu];
	
	
	[menu addItem:[NSMenuItem separatorItem]];
	
	item = [menu addItemWithTitle:@"About Soundflowerbed..." action:@selector(doNothing) keyEquivalent:@""];
	[item setTarget:self];
	
	item = [menu addItemWithTitle:@"Quit Soundflowerbed" action:@selector(doQuit) keyEquivalent:@""];
	[item setTarget:self];
	
	
	[sbItem setMenu:menu];
}

- (void)doNothing
{

}

- (void)doQuit
{
	[NSApp terminate:nil];
}



@end
