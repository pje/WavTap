#import <Cocoa/Cocoa.h>
#include "AudioDeviceList.h"
#include "AudioThruEngine.h"

@interface AppController : NSObject
{
  NSStatusItem *mSbItem;
  NSMenu *mMenu;
  AudioThruEngine *mEngine;
}
- (void)toggleRecord;
@end

NSDictionary *mMenuItemTags;
EventHandlerUPP hotKeyFunction;
BOOL menuItemVisible;
BOOL mIsRecording;
Float32 mStashedVolume;
Float32 mStashedVolume2;
AudioDeviceID mStashedAudioDeviceID;
AudioDeviceID mWavTapDeviceID;
AudioDeviceID mOutputDeviceID;
AudioDeviceList *mOutputDeviceList;
