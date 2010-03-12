//
//  SFSender.h
//  Soundfly
//
//  Created by JuL on 11/02/07.
//  Copyright 2007 abyssoft. All rights reserved.
//

#import "SFAUModule.h"

@interface SFSender : SFAUModule
{
	AudioDeviceID _outputDeviceID;
	AudioDeviceID _soundflowerDeviceID;
    
	AudioUnit _inputUnit;
	AudioUnit _netSendUnit;
}

@end
