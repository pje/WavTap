//
//  SFCommunicationManager.m
//  Soundfly
//
//  Created by Julien Robert on 16/02/08.
//  Copyright 2008 abyssoft. All rights reserved.
//

#import "SFCommunicationManager.h"

NSString * SFQuitDaemonNotification = @"SFQuitDaemonNotification";
NSString * SFRequestStatusUpdateNotification = @"SFRequestStatusUpdateNotification";

NSString * SFParameterDidChangeNotification = @"SFParameterDidChangeNotification";

static SFCommunicationManager * _sharedManager = nil;

@implementation SFCommunicationManager

+ (SFCommunicationManager*)sharedManager
{
    if(_sharedManager == nil) {
        _sharedManager = [[SFCommunicationManager alloc] init];
    }
    
    return _sharedManager;
}

- init
{
	self = [super init];
	
	NSString * appDomainName = [[NSBundle mainBundle] bundleIdentifier];
	NSString * domainName = [[NSBundle bundleForClass:[self class]] bundleIdentifier];
	_isDaemon = [domainName isEqualToString:appDomainName];
	
	return self;
}

- (void)setDelegate:(id)delegate
{
    _delegate = delegate;
}

- (void)startListeners
{
    if(_isDaemon) {
        [[NSDistributedNotificationCenter defaultCenter] addObserver:NSApp selector:@selector(terminate:) name:SFQuitDaemonNotification object:nil];
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(_requestStatusUpdate:) name:SFRequestStatusUpdateNotification object:nil];
	}
	else {
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(_parameterDidChange:) name:SFParameterDidChangeNotification object:nil];
	}
    
}

- (void)stopListeners
{
    if(_isDaemon) {
        [[NSDistributedNotificationCenter defaultCenter] removeObserver:NSApp name:SFQuitDaemonNotification object:nil];
        [[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:SFRequestStatusUpdateNotification object:nil];

	}
	else {
        [[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:SFParameterDidChangeNotification object:nil];
	}
}

- (void)quitDaemon
{
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:SFQuitDaemonNotification object:nil];
}

- (void)requestStatusUpdate
{
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:SFRequestStatusUpdateNotification object:nil];
}

- (void)moduleWithID:(NSString*)moduleID didChangeParameter:(AudioUnitParameterID)parameterID toValue:(Float32)value
{
    NSDictionary * userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                               moduleID, @"moduleID",
                               [NSNumber numberWithInt:parameterID], @"parameterID",
                               [NSNumber numberWithFloat:value], @"value",
                               nil];
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:SFParameterDidChangeNotification object:moduleID userInfo:userInfo];
}

- (void)_parameterDidChange:(NSNotification*)notification
{
    if(_delegate != nil && [_delegate respondsToSelector:@selector(moduleWithID:didChangeParameter:toValue:)]) {
        NSDictionary * userInfo = [notification userInfo];
        NSString * moduleID = [userInfo objectForKey:@"moduleID"];
        AudioUnitParameterID parameterID = [[userInfo objectForKey:@"parameterID"] intValue];
        Float32 value = [[userInfo objectForKey:@"value"] floatValue];
        [_delegate moduleWithID:moduleID didChangeParameter:parameterID toValue:value];
    }
}

- (void)_requestStatusUpdate:(NSNotification*)notification
{
    if(_delegate != nil && [_delegate respondsToSelector:@selector(requestStatusUpdate)]) {
        [_delegate requestStatusUpdate];
    }
}

@end
