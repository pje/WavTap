#import <Cocoa/Cocoa.h>
#include "AudioDeviceList.h"

@interface AppController : NSObject
{
  NSStatusItem *mSbItem;
  NSMenu *mMenu;
}
- (void)sampleRateChanged;
- (void)sampleRateChangedOutput;
- (void)toggleRecord;
@end
EventHandlerUPP hotKeyFunction;
BOOL menuItemVisible;
BOOL mIsRecording;
Float32 mStashedVolume;
Float32 mStashedVolume2;
AudioDeviceID mStashedAudioDeviceID;
AudioDeviceID mWavTapDeviceID;
AudioDeviceID mOutputDeviceID;
AudioDeviceList *mOutputDeviceList;
