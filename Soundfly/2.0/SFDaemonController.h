//
//  SFDaemonController.h
//  Soundfly
//
//  Created by Julien Robert on 15/02/08.
//  Copyright 2008 abyssoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "SFSender.h"
#import "SFReceiver.h"

@class SFStatusItemController;

@interface SFDaemonController : NSObject
{
    NSConnection * _connection;
    
    SFSender * _sender;
    SFReceiver * _receiver;
    
    SFStatusItemController * _statusItemController;
}

@end
