#import "HelpWindowController.h"

@implementation HelpWindowController

- (void)awakeFromNib
{
}

- (void)doAbout
{
  [self showWindow:[self window]];
  [NSApp activateIgnoringOtherApps:YES];
}
@end
