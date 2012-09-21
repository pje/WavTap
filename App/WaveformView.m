#import "WaveformView.h"

@implementation WaveformView

- (id)initWithFrame:(NSRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    NSLog(@"initWithFrame");
  }  
  return self;
}

- (void)drawRect:(NSRect)dirtyRect {
  NSLog(@"drawRect");
  CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];

  UInt32 sampleWidthInPixels = 5;
  UInt32 currentSampleIndex = 0;
  UInt32 sampleAmplitude = 0;
  
  CGContextSetRGBFillColor(context, 0.01, 0.01, 0.01, 1);

  for(int i = 0; i < 300; i ++){
    CGContextFillRect(context, CGRectMake(i * sampleWidthInPixels, 0, i * sampleWidthInPixels, i));
  }
}

- (void)drawSample:(UInt32)amplitude {

}

@end
