#import "SFPrefPaneAppController.h"

@implementation SFPrefPaneAppController

- (void) awakeFromNib 
{ 
	NSRect aRect; 
	NSString *pathToPrefPaneBundle; 
	NSBundle *prefBundle; 
	Class prefPaneClass; 
	NSPreferencePane *prefPaneObject; 
	NSView *prefView; 
	
#if 1
	pathToPrefPaneBundle = [@"~/Projects/Builds/Debug/Soundfly.prefPane" stringByExpandingTildeInPath];
#else
	pathToPrefPaneBundle = [@"~/Projects/Builds/Release/Soundfly.prefPane" stringByExpandingTildeInPath]; 
#endif
	
	prefBundle = [NSBundle bundleWithPath: pathToPrefPaneBundle]; 
	[prefBundle load];
	prefPaneClass = [prefBundle principalClass]; 
	prefPaneObject = [[prefPaneClass alloc] initWithBundle: prefBundle]; 
	
	if([prefPaneObject loadMainView] ) 
	{ 
		[prefPaneObject willSelect]; 
		prefView = [prefPaneObject mainView]; 
		/* Add view to window */ 
		aRect = [prefView frame]; 
		
		// Okay, I know this is not so goood... 
		aRect.size.height = aRect.size.height + 22;
		aRect.origin = NSMakePoint(200,200);
		[window setFrame: aRect display: YES]; 
		[[window contentView] addSubview: prefView];
		[[window contentView] setAutoresizesSubviews:YES];//:NSViewWidthSizable | NSViewHeightSizable];
		
		[prefView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
		[prefPaneObject didSelect];
	}
	else
	{
		/* loadMainView failed -- handle error */ 
		NSLog(@"Error !!!"); 
	}
}

@end
