//
//  SFReceiver.h
//  Soundfly
//
//  Created by JuL on 20/02/07.
//  Copyright 2007 abyssoft. All rights reserved.
//

#import "SFAUModule.h"

@interface SFReceiver : SFAUModule
{
	AudioDeviceID _outputDeviceID;
    
	AudioUnit _outputUnit;
	AudioUnit _netReceiveUnit;
}

@end
