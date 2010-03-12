//
//  SFClosingWindow.m
//  Soundfly
//
//  Created by JuL on Mon Jan 26 2004.
//  Copyright (c) 2003-2005 abyssoft. All rights reserved.
//

#import "SFClosingWindow.h"

@implementation SFClosingWindow

- (void)keyDown:(NSEvent*)event
{
	[[self delegate] closeAboutSheet];
}

- (void)mouseDown:(NSEvent*)event
{
	[[self delegate] closeAboutSheet];
}

@end
