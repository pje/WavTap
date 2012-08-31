#import <Cocoa/Cocoa.h>
#include "AudioDeviceList.h"

@interface AppController : NSObject
{
  NSStatusItem *mSbItem;
  NSMenu *mMenu;
  BOOL menuItemVisible;
  BOOL mIsRecording;
  Float32 mStashedVolume;
  Float32 mStashedVolume2;
  AudioDeviceID mStashedAudioDeviceID;
  AudioDeviceID mWavTapDeviceID;
  AudioDeviceID mOutputDeviceID;
  AudioDeviceList *mOutputDeviceList;
  EventHandlerUPP hotKeyFunction;
}
- (IBAction)sampleRateChanged;
- (IBAction)sampleRateChangedOutput;
- (OSStatus)restoreSystemOutputDevice;
- (void)initConnections;
- (void)toggleRecord;
- (void)buildMenu;
- (void)bindHotKeys;
@end
