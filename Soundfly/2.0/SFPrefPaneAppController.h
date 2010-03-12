/* SFPrefPaneAppController */

#import <Cocoa/Cocoa.h>
#import <PreferencePanes/PreferencePanes.h>

@interface SFPrefPaneAppController : NSObject
{
	NSPreferencePane * prefPane;
	IBOutlet NSWindow * window;
}
@end
