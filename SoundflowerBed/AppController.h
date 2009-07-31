/* AppController */

#import <Cocoa/Cocoa.h>
#import "HelpWindowController.h"
#include "AudioDeviceList.h"


@interface AppController : NSObject
{
	NSStatusItem	*mSbItem;
	NSMenu			*mMenu;
	NSMenuItem		*m2chMenu;
	NSMenuItem		*m16chMenu;
	NSMenu			*m2chBuffer;
	NSMenu			*m16chBuffer;
    
	BOOL			menuItemVisible;
	int				m16StartIndex;
	
	NSMenuItem		*mCur2chDevice;
	NSMenuItem		*mCur16chDevice;
	NSMenuItem		*mCur2chBufferSize;
	NSMenuItem		*mCur16chBufferSize;
	
	NSMenuItem		*mSuspended2chDevice;
	NSMenuItem		*mSuspended16chDevice;
	
	AudioDeviceID				mSoundflower2Device;
	AudioDeviceID				mSoundflower16Device;
	
	AudioDeviceList *			mOutputDeviceList;	
	
	UInt32 mNchnls2;
	UInt32 mNchnls16;
	
	UInt32 mMenuID2[64];
	UInt32 mMenuID16[64];
	
	IBOutlet HelpWindowController *mAboutController;
}

- (IBAction)suspend;
- (IBAction)resume;

- (IBAction)srChanged2ch;
- (IBAction)srChanged16ch;
- (IBAction)srChanged2chOutput;
- (IBAction)srChanged16chOutput;
- (IBAction)checkNchnls;

- (IBAction)refreshDevices;

- (IBAction)outputDeviceSelected:(id)sender;
- (IBAction)bufferSizeChanged2ch:(id)sender;
- (IBAction)bufferSizeChanged16ch:(id)sender;
- (IBAction)routingChanged2ch:(id)sender;
- (IBAction)routingChanged16ch:(id)sender;

- (void)buildRoutingMenu:(BOOL)is2ch;
- (void)buildDeviceList;
- (void)buildMenu;

- (void)InstallListeners;
- (void)RemoveListeners;

- (void)readGlobalPrefs;
- (void)writeGlobalPrefs;

- (void)readDevicePrefs:(BOOL)is2ch;
- (void)writeDevicePrefs:(BOOL)is2ch;

//- (IBAction)inputLoadChanged:(id)sender;
//- (IBAction)outputLoadChanged:(id)sender;
//- (IBAction)extraLatencyChanged:(id)sender;
//- (IBAction)toggleThru:(id)sender;
//- (IBAction)inputDeviceSelected:(id)sender;
//- (IBAction)inputSourceSelected:(id)sender;
//- (IBAction)outputSourceSelected:(id)sender;
//- (void)updateActualLatency:(NSTimer *)timer;

@end
