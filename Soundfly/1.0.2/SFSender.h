//
//  SFSender.h
//  Soundfly
//
//  Created by JuL on 11/02/07.
//  Copyright 2007 abyssoft. All rights reserved.
//

#import "SFCommon.h"

@interface SFSender : NSObject
{
	AudioDeviceID _outputDeviceID;
	AudioDeviceID _soundflowerDeviceID;
	AudioUnit _inputUnit;
	AudioUnit _netSendUnit;
	AUGraph _graph;
}

- (IBAction)showOptions:(id)sender;

@end
