//
//  SFDaemonManager.h
//  Soundfly
//
//  Created by JuL on 09/02/06.
//  Copyright 2006 abyssoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SFDaemonManager : NSObject
{
	NSConnection * _connection;
	id _daemonProxy;
	id _delegate;
}

+ (SFDaemonManager*)manager;

- (void)launchDaemonIfNeeded;
- (void)launchDaemon;
- (void)terminateDaemon;

- (BOOL)isDaemonRunning;

- (void)registerDaemonIfNeeded;
- (void)unregisterDaemon;

- (void)setDelegate:(id)delegate;

@end

@interface NSObject (SFDaemonManagerDelegate)

- (void)daemonDidDie;

@end
