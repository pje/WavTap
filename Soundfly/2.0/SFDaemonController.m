//
//  SFDaemonController.m
//  Soundfly
//
//  Created by Julien Robert on 15/02/08.
//  Copyright 2008 abyssoft. All rights reserved.
//

#import "SFDaemonController.h"

#import "SFPreferencesManager.h"
#import "SFCommunicationManager.h"

#import "SFStatusItemController.h"

@interface SFDaemonController ()

- (void)_registerConnection;
- (void)_unregisterConnection;

@end

@implementation SFDaemonController

- init
{
    self = [super init];
    
    _sender = [[SFSender alloc] init];
    _receiver = [[SFReceiver alloc] init];
    _statusItemController = [[SFStatusItemController alloc] init];
    
    [_sender setDelegate:self];
    [_receiver setDelegate:self];
    [_statusItemController setDelegate:self];
    [[SFCommunicationManager sharedManager] setDelegate:self];
    
    return self;
}

- (void)dealloc
{
    [_sender release];
    [_receiver release];
    [super dealloc];
}

- (void)awakeFromNib
{
    [self _registerConnection];
    
    [_sender bind:@"active" toPref:SENDER_ACTIVE];
    [_receiver bind:@"active" toPref:RECEIVER_ACTIVE];
    [_statusItemController bind:@"showStatusItem" toPref:SHOW_STATUS_ITEM];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [_sender setActive:NO];
    [_receiver setActive:NO];
}

- (void)_registerConnection
{
	if(_connection == nil) {
        NSString * connectionName = [[SFPreferencesManager sharedPreferencesManager] daemonConnectionName];

		/* Kill already launched daemon */
        [[SFCommunicationManager sharedManager] quitDaemon];
		
		/* Register new one */
		_connection = [NSConnection defaultConnection];
		
		if([_connection registerName:connectionName]) {
			//NSLog(@"REGISTER DAEMON %@ with name %@", self, connectionName);
            
            [[SFCommunicationManager sharedManager] startListeners];
        }
		else {
			_connection = nil;
			NSLog(@"error registering %@", self);
		}
	}
}

- (void)_unregisterConnection
{
	if(_connection != nil) {
		[_connection registerName:nil];
		_connection = nil;
        
        [[SFCommunicationManager sharedManager] stopListeners];
	}
}

- (void)_updateStatusForModule:(SFAUModule*)module
{
    int status = [module status];
    [[SFCommunicationManager sharedManager] moduleWithID:[module moduleID] didChangeParameter:kAUNetReceiveParam_Status toValue:status];
    
    if(module == _receiver) {
        [_statusItemController setStreaming:(status == kAUNetStatus_Connected)];
    }
}

- (void)requestStatusUpdate
{
    [self _updateStatusForModule:_sender];
    [self _updateStatusForModule:_receiver];
}

- (void)moduleDidActivate:(SFAUModule*)module
{
    [self _updateStatusForModule:module];
}

- (void)module:(SFAUModule*)module didChangeStatus:(int)status
{
    [self _updateStatusForModule:module];
}

- (void)resetLag
{
    if([_sender active]) {
        [_sender setActive:NO];
        [_sender setActive:YES];
    }
}

@end
