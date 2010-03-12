//
//  SFLinkTextField.m
//  Soundfly
//
//  Created by JuL on 10/07/05.
//  Copyright 2005 abyssoft. All rights reserved.
//

#import "SFLinkTextField.h"

static NSColor * _highlightedColor = nil;
static NSColor * _normalColor = nil;

@implementation SFLinkTextField

+ (void)initialize
{
	if(self == [SFLinkTextField class]) {
		_highlightedColor = [[NSColor colorWithCalibratedWhite:0.25 alpha:1.0] retain];
		_normalColor = [[NSColor blackColor] retain];
	}
}

- initWithCoder:(NSCoder*)coder
{
	self = [super initWithCoder:coder];
	
	_trackingRectTag = -1;
	
	return self;
}

- initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	
	_trackingRectTag = -1;
	
	return self;
}

- (void)dealloc
{
	if(_trackingRectTag > 0)
		[self removeTrackingRect:_trackingRectTag];
	[super dealloc];
}

- (void)_resetTrackingRect
{
	if(_trackingRectTag > 0)
		[self removeTrackingRect:_trackingRectTag];
	if([self window] != nil)
		_trackingRectTag = [self addTrackingRect:[self bounds] owner:self userData:NULL assumeInside:NO];
}

- (void)awakeFromNib
{
	[self _resetTrackingRect];
}

- (void)viewDidMoveToWindow
{
	[self _resetTrackingRect];
}

- (void)viewDidMoveToSuperview
{
	[self _resetTrackingRect];
}

- (void)setFrameSize:(NSSize)size
{
	[super setFrameSize:size];
	[self _resetTrackingRect];
}

- (void)setFrameOrigin:(NSPoint)origin
{
	[super setFrameOrigin:origin];
	[self _resetTrackingRect];
}

- (void)mouseEntered:(NSEvent*)event
{
	[self setTextColor:_highlightedColor];
	[[NSCursor pointingHandCursor] push];
	[self setNeedsDisplay:YES];
}

- (void)mouseExited:(NSEvent*)event
{
	[self setTextColor:_normalColor];
	[NSCursor pop];
	[self setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent*)event
{
	NSURL * url = [NSURL URLWithString:[(NSTextFieldCell*)[self cell] placeholderString]];
	if(url != nil)
		[[NSWorkspace sharedWorkspace] openURL:url];
}

@end
