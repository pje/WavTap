#import <Cocoa/Cocoa.h>
#import "HelpWindowController.h"
#include "AudioDeviceList.h"

@interface AppController : NSObject
{
  NSStatusItem *mSbItem;
  NSMenu *mMenu;
  NSMenuItem *m2chMenu;
  NSMenu *m2chBuffer;
  BOOL menuItemVisible;
  BOOL mIsRecording;
  NSMenuItem *mCur2chDevice;
  NSMenuItem *mCur2chBufferSize;
  NSMenuItem *mSuspended2chDevice;
  AudioDeviceID mSoundflower2Device;
  AudioDeviceList *mOutputDeviceList;
  UInt32 mNchnls2;
  UInt32 mMenuID2[64];
  IBOutlet HelpWindowController *mAboutController;
}
- (IBAction)suspend;
- (IBAction)resume;
- (IBAction)srChanged2ch;
- (IBAction)srChanged2chOutput;
- (IBAction)checkNchnls;
- (IBAction)refreshDevices;
- (IBAction)outputDeviceSelected:(id)sender;
- (IBAction)bufferSizeChanged2ch:(id)sender;
- (IBAction)cloningChanged:(id)sender;
- (IBAction)cloningChanged:(id)sender cloneChannels:(bool)clone;
- (IBAction)routingChanged2ch:(id)sender;
- (void)doToggleRecord;
- (void)buildRoutingMenu:(BOOL)is2ch;
- (void)buildDeviceList;
- (void)buildMenu;
- (void)bindHotKeys;
- (void)InstallListeners;
- (void)RemoveListeners;
- (void)readGlobalPrefs;
- (void)writeGlobalPrefs;
- (void)readDevicePrefs:(BOOL)is2ch;
- (void)writeDevicePrefs:(BOOL)is2ch;
@end
