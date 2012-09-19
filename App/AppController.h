#ifndef __AppController_h__
#define __AppController_h__
#include <Cocoa/Cocoa.h>
#include "AudioTee.h"

@interface
AppController : NSObject {
  NSStatusItem *mSbItem;
  NSMenu *mMenu;
  AudioTee *mEngine;
}

- (void)toggleRecord;
- (void)historyRecord;
@end

bool mIsRecording;
UInt32 mTagForToggleRecord;
UInt32 mTagForHistoryRecord;
UInt32 mTagForQuit;
EventHandlerUPP recordHotKeyFunction;
EventHandlerUPP historyRecordHotKeyFunction;
Float32 mStashedVolume;
Float32 mStashedVolume2;
AudioDeviceID mStashedAudioDeviceID;
AudioDeviceID mWavTapDeviceID;
AudioDeviceID mOutputDeviceID;
struct Device {
  char mName[64];
  AudioDeviceID mID;
};
std::vector<Device> *mDevices;
UInt32 currentFrame;
UInt32 totalFrames;
NSTimer *animTimer;
NSTimer *timeElapsedTimer;

#endif
