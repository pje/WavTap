#import <Cocoa/Cocoa.h>

@interface HelpWindowController : NSWindowController
{
  IBOutlet NSTextView *mTextView;
}

- (void)doAbout;

@end
