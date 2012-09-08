#include <Cocoa/Cocoa.h>
#include "AudioDeviceList.h"
#include "AudioTee.h"

@interface
AppController : NSObject {
  NSStatusItem *mSbItem;
  NSMenu *mMenu;
  AudioTee *mEngine;
}

- (void)toggleRecord;
@end

NSDictionary *mMenuItemTags;
EventHandlerUPP hotKeyFunction;
bool menuItemVisible;
bool mIsRecording;
bool mHistoryRecordIsStopping;
Float32 mStashedVolume;
Float32 mStashedVolume2;
AudioDeviceID mStashedAudioDeviceID;
AudioDeviceID mWavTapDeviceID;
AudioDeviceID mOutputDeviceID;
AudioDeviceList *mOutputDeviceList;
