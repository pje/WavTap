//
//  SFReceiver.h
//  Soundfly
//
//  Created by JuL on 20/02/07.
//  Copyright 2007 abyssoft. All rights reserved.
//

#import "SFCommon.h"

@interface SFReceiver : NSObject
{
	AudioDeviceID _outputDeviceID;
	AudioUnit _outputUnit;
	AudioUnit _netReceiveUnit;
	AUGraph _graph;
}

- (IBAction)showOptions:(id)sender;

@end
