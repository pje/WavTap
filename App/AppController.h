#include <Cocoa/Cocoa.h>
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
struct Device {
  char mName[64];
  AudioDeviceID mID;
};
typedef std::vector<Device> AudioDeviceList;
AudioDeviceList *mDevices;
