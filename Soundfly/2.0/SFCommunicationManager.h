//
//  SFCommunicationManager.h
//  Soundfly
//
//  Created by Julien Robert on 16/02/08.
//  Copyright 2008 abyssoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SFCommon.h"

@interface SFCommunicationManager : NSObject
{
    BOOL _isDaemon;
    
    id _delegate;
}

+ (SFCommunicationManager*)sharedManager;

- (void)setDelegate:(id)delegate;

- (void)startListeners;
- (void)stopListeners;

- (void)quitDaemon;
- (void)requestStatusUpdate;

- (void)moduleWithID:(NSString*)moduleID didChangeParameter:(AudioUnitParameterID)parameterID toValue:(Float32)value;

@end

@interface NSObject (SFCommunicationDelegate)

- (void)moduleWithID:(NSString*)moduleID didChangeParameter:(AudioUnitParameterID)parameterID toValue:(Float32)value;
- (void)requestStatusUpdate;

@end
