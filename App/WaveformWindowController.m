#include "WaveformWindowController.h"

@interface WaveformWindowController ()

@end

@implementation WaveformWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
      NSLog(@"initWithWindow");
    }

    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    NSLog(@"windowDidLoad");
}

@end
