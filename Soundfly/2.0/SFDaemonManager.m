//
//  SFDaemonManager.m
//  Soundfly
//
//  Created by JuL on 09/02/06.
//  Copyright 2006 abyssoft. All rights reserved.
//

#import "SFDaemonManager.h"

#import "SFPreferencesManager.h"
#import "SFCommunicationManager.h"

#import <unistd.h>
#import <signal.h>
#import <sys/types.h>
#import <sys/sysctl.h>
#import <sys/param.h>
#import <sys/mount.h>

static SFDaemonManager * _manager = nil;

@implementation SFDaemonManager

+ (SFDaemonManager*)manager
{
	if(_manager == nil)
		_manager = [[SFDaemonManager alloc] init];
	return _manager;
}


#pragma mark -
#pragma mark Start/stop daemon

- (void)launchDaemonIfNeeded
{
	if(![self isDaemonRunning])
		[self launchDaemon];
}

- (void)launchDaemon
{
	//return; // temp disabled
	NSBundle * mainBundle = [NSBundle bundleForClass:[self class]];
	NSString * daemonPath = [mainBundle pathForResource:SOUNDFLY_DAEMON ofType:@"app"];
	[[NSWorkspace sharedWorkspace] openFile:nil withApplication:daemonPath andDeactivate:NO];
}

- (void)terminateDaemon
{
    [[SFCommunicationManager sharedManager] quitDaemon];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSConnectionDidDieNotification object:_connection];
	[_connection invalidate];
	[_connection release];
    _connection = nil;
}


#pragma mark -
#pragma mark Registering/Unregistering in login items

- (void)registerDaemonIfNeeded
{
	NSMutableDictionary * myDict = [[NSMutableDictionary alloc] init];
	NSUserDefaults * defaults = [[NSUserDefaults alloc] init];
	NSBundle * mainBundle = [NSBundle bundleForClass:[self class]];
	NSMutableArray * loginItems;
	NSMutableDictionary *newLoginDefaults;
	
	[defaults addSuiteNamed:@"loginwindow"];
	
	[myDict setObject:[NSNumber numberWithBool:NO] forKey:@"Hide"];
	[myDict setObject:[mainBundle pathForResource:SOUNDFLY_DAEMON ofType:@"app"] forKey:@"Path"];
	
	loginItems = [[NSMutableArray alloc] init];
	[loginItems addObjectsFromArray:[[defaults persistentDomainForName:@"loginwindow"] objectForKey:@"AutoLaunchedApplicationDictionary"]];
	
	/* Remove old Soundfly login items */
	NSMutableIndexSet * indexesToRemove = [[NSMutableIndexSet alloc] init];
	
	int index = 0;
	int count = [loginItems count];
	
	for(index = 0; index < count; index++) {
		NSDictionary * loginItem = [loginItems objectAtIndex:index];
		NSString * path = [loginItem objectForKey:@"Path"];
		if([[path lastPathComponent] isEqualToString:[SOUNDFLY_DAEMON stringByAppendingPathExtension:@"app"]])
			[indexesToRemove addIndex:index];
	}
	
	if([loginItems respondsToSelector:@selector(removeObjectsAtIndexes:)])
		[loginItems removeObjectsAtIndexes:indexesToRemove];
	else {
		unsigned i = [indexesToRemove lastIndex];
		while(i != NSNotFound) {
			[loginItems removeObjectAtIndex:i];
			i = [indexesToRemove indexLessThanIndex:i];
		}
	}
	[indexesToRemove release];
	
	/* Add new */
	[loginItems addObject:myDict];
	[myDict release];
	
	newLoginDefaults = [NSMutableDictionary dictionaryWithDictionary:[defaults persistentDomainForName:@"loginwindow"]];
	[newLoginDefaults setObject:loginItems forKey:@"AutoLaunchedApplicationDictionary"];
	[defaults setPersistentDomain:newLoginDefaults forName:@"loginwindow"];
	[defaults synchronize];
	[defaults release];
	[loginItems release];
}

- (void)unregisterDaemon
{
	NSUserDefaults * defaults = [[NSUserDefaults alloc] init];
	NSMutableArray * loginItems;
	NSMutableDictionary *newLoginDefaults;
	
	[defaults addSuiteNamed:@"loginwindow"];
	
	loginItems = [[NSMutableArray alloc] init];
	[loginItems addObjectsFromArray:[[defaults persistentDomainForName:@"loginwindow"] objectForKey:@"AutoLaunchedApplicationDictionary"]];
	
	/* Remove old Soundfly login items */
	NSMutableIndexSet * indexesToRemove = [[NSMutableIndexSet alloc] init];
	
	int index = 0;
	int count = [loginItems count];
	
	for(index = 0; index < count; index++) {
		NSDictionary * loginItem = [loginItems objectAtIndex:index];
		NSString * path = [loginItem objectForKey:@"Path"];
		if([[path lastPathComponent] isEqualToString:[SOUNDFLY_DAEMON stringByAppendingPathExtension:@"app"]])
			[indexesToRemove addIndex:index];
	}
	
	if([loginItems respondsToSelector:@selector(removeObjectsAtIndexes:)])
		[loginItems removeObjectsAtIndexes:indexesToRemove];
	else {
		unsigned i = [indexesToRemove lastIndex];
		while(i != NSNotFound) {
			[loginItems removeObjectAtIndex:i];
			i = [indexesToRemove indexLessThanIndex:i];
		}
	}
	[indexesToRemove release];
	
	newLoginDefaults = [NSMutableDictionary dictionaryWithDictionary:[defaults persistentDomainForName:@"loginwindow"]];
	[newLoginDefaults setObject:loginItems forKey:@"AutoLaunchedApplicationDictionary"];
	[defaults setPersistentDomain:newLoginDefaults forName:@"loginwindow"];
	[defaults synchronize];
	[defaults release];
	[loginItems release];
}


#pragma mark -
#pragma mark Daemon proxy

- (BOOL)_connectToDaemon
{
	if(_connection == nil) {
		NSString * connectionName = [[SFPreferencesManager sharedPreferencesManager] daemonConnectionName];
		_connection = [[NSConnection connectionWithRegisteredName:connectionName host:nil] retain];
        if(_connection != nil) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_daemonDidDie:) name:NSConnectionDidDieNotification object:_connection];
            return YES;
        }
        else {
            return NO;
        }
	}
    else {
        return YES;
    }
}
	
- (BOOL)isDaemonRunning
{
	return [self _connectToDaemon];
}

- (void)setDelegate:(id)delegate
{
	_delegate = delegate;
}

- (void)_daemonDidDie:(NSNotification*)notification
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSConnectionDidDieNotification object:[notification object]];
    
	NSLog(@"daemon did die");
    
    [_connection invalidate];
	[_connection release];
    _connection = nil;

	if(_delegate != nil && [_delegate respondsToSelector:@selector(daemonDidDie)])
		[_delegate daemonDidDie];
}

@end
