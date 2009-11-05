//
//  SFUtils.m
//  teleport
//
//  Created by Julien Robert on 11/10/05.
//  Copyright 2005 abyssoft. All rights reserved.
//

#import "SFUtils.h"

@implementation NSWorkspace (SFAdditions)

- (void)showPreferencesPaneWithID:(NSString*)prefPaneID async:(BOOL)async
{
	NSString * appleScriptSource = [NSString stringWithFormat:@"tell application \"System Preferences\"\nactivate\nset current pane to pane id \"%@\"\nend tell", prefPaneID];
	NSAppleScript * script = [[NSAppleScript alloc] initWithSource:appleScriptSource];
	
	if(async)
		[NSThread detachNewThreadSelector:@selector(_executeThreadedScript:) toTarget:self withObject:script];
	else
		[script executeAndReturnError:NULL];
	
	[script release];
}

- (void)_executeThreadedScript:(NSAppleScript*)script
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	[script executeAndReturnError:NULL];
	[pool release];
}

@end
