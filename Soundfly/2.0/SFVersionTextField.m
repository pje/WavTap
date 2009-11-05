//
//  SFVersionTextField.m
//  Soundfly
//
//  Created by JuL on Sat Feb 28 2004.
//  Copyright (c) 2003-2005 abyssoft. All rights reserved.
//

#import "SFVersionTextField.h"


@implementation SFVersionTextField

- (void)_commonInit
{
	_currentVersionIndex = -1;
	_versions = nil;
}

- initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];

	[self _commonInit];
	
	return self;
}

- initWithCoder:(NSCoder*)coder
{
	self = [super initWithCoder:coder];
	
	[self _commonInit];
	
	return self;
}

- (void)dealloc
{
	[_versions release];
	[super dealloc];
}

- (void)setVersions:(NSArray*)versions
{
	if(versions != _versions) {
		[_versions release];
		_versions = [versions retain];
		[self changeVersion];
	}
}

- (NSArray*)versions
{
    return _versions;
}

- (void)mouseDown:(NSEvent*)event
{
	[self changeVersion];
}

- (void)changeVersion
{
	if(_versions == nil || [_versions count] == 0)
		return;
	
	if(++_currentVersionIndex == [_versions count])
		_currentVersionIndex = 0;
	
	NSString * version = [_versions objectAtIndex:_currentVersionIndex];
	
	[self setStringValue:version];
}

@end
