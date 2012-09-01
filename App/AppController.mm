#import <Carbon/Carbon.h>
#import <AudioUnit/AudioUnit.h>
#include "AppController.h"
#include "AudioThruEngine.h"

@implementation AppController

AudioThruEngine *gThruEngine2 = NULL;
UInt32 MENU_ITEM_TAG_TOGGLE_RECORD=1;
io_connect_t  root_port;

- (id)init
{
  mMenuItemTags = [[NSDictionary alloc] initWithObjectsAndKeys:
                   @"toggleRecord", @1,
                   @"preferences",  @2,
                   @"quit",         @3,
                   nil];
  mIsRecording = NO;
  mOutputDeviceList = NULL;
  mWavTapDeviceID = 0;
  return self;
}

- (void)dealloc
{
  delete mOutputDeviceList;
}

- (void)awakeFromNib
{
  [[NSApplication sharedApplication] setDelegate:(id)self];
  //  [self doRegisterForSystemPower];
  [self rebuildDeviceList];
  AudioDeviceList::DeviceList &list = mOutputDeviceList->GetList();
  for (AudioDeviceList::DeviceList::iterator i = list.begin(); i != list.end(); ++i) {
    if (0 == strcmp("WavTap (2ch)", (*i).mName)) mWavTapDeviceID = (*i).mID;
  }
  [self initConnections];
  [self bindHotKeys];
  [self initStatusBar];
  [self buildMenu];
}

- (void)initStatusBar
{
  mSbItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
  [mSbItem setImage:[NSImage imageNamed:@"menuIcon"]];
  [mSbItem setHighlightMode:YES];
}

- (void)buildMenu
{
  NSMenuItem *item;
  mMenu = [[NSMenu alloc] initWithTitle:@"Main Menu"];

  if (mWavTapDeviceID){
    item = [mMenu addItemWithTitle:@"Record" action:@selector(toggleRecord) keyEquivalent:@""];
    [item setTarget:self];
    [item setTag:(NSInteger)[mMenuItemTags objectForKey:@"toggleRecord"]];
    [self setToggleRecordHotKey:@" "];
  } else {
    item = [mMenu addItemWithTitle:@"Kernel Extension Not Installed" action:NULL keyEquivalent:@""];
    [item setTarget:self];
  }

  [mMenu addItem:[NSMenuItem separatorItem]];
  [mSbItem setMenu:mMenu];

  //  item = [mMenu addItemWithTitle:@"Preferences..." action:@selector(showPreferencesWindow) keyEquivalent:@","];
  //  [item setKeyEquivalentModifierMask:NSCommandKeyMask];
  //  [item setTag:(NSInteger)[mMenuItemTags objectForKey:@"preferences"]];
  //  [item setTarget:self];

  item = [mMenu addItemWithTitle:@"Quit" action:@selector(doQuit) keyEquivalent:@""];
  [item setTag:(NSInteger)[mMenuItemTags objectForKey:@"quit"]];
  [item setTarget:self];
}

void MySleepCallBack(void * x, io_service_t y, natural_t messageType, void * messageArgument)
{
  AppController *app = (__bridge AppController *)x;
    switch ( messageType ) {
      case kIOMessageSystemWillSleep:
        [NSThread detachNewThreadSelector:@selector(suspend) toTarget:app withObject:nil];
        IOAllowPowerChange(root_port, (long)messageArgument);
        break;
      case kIOMessageSystemWillNotSleep:
        break;
      case kIOMessageCanSystemSleep:
        IOAllowPowerChange(root_port, (long)messageArgument);
        break;
      case kIOMessageSystemHasPoweredOn:
        [NSTimer scheduledTimerWithTimeInterval:0.0 target:app selector:@selector(resume) userInfo:nil repeats:NO];
        break;
      default:
        break;
    }
}

- (void)doRegisterForSystemPower
{
  IONotificationPortRef notify;
  io_object_t anIterator;
  root_port = IORegisterForSystemPower((__bridge void *) self, &notify, MySleepCallBack, &anIterator);
  if (!root_port) {
    NSLog(@"IORegisterForSystemPower failed\n");
  } else {
    CFRunLoopAddSource(CFRunLoopGetCurrent(), IONotificationPortGetRunLoopSource(notify), kCFRunLoopCommonModes);
  }
}

- (IBAction)sampleRateChanged
{
  @autoreleasepool {
    OSStatus err = noErr;
    gThruEngine2->Mute(true);
    err = gThruEngine2->MatchSampleRate(true);
    gThruEngine2->Mute(false);
  }
}

- (IBAction)sampleRateChangedOutput
{
  @autoreleasepool {
    OSStatus err = noErr;
    gThruEngine2->Mute(true);
    err = gThruEngine2->MatchSampleRate(false);
    gThruEngine2->Mute(false);
  }
}

- (void)setToggleRecordHotKey:(NSString*)keyEquivalent
{
  NSMenuItem *item = [mMenu itemWithTag:(NSInteger)[mMenuItemTags objectForKey:@"toggleRecord"]];
  [item setKeyEquivalentModifierMask: NSControlKeyMask | NSCommandKeyMask];
  [item setKeyEquivalent:keyEquivalent];
}

- (void)rebuildDeviceList
{
  if (mOutputDeviceList) delete mOutputDeviceList;
  mOutputDeviceList = new AudioDeviceList;
}

- (void)initConnections
{
  OSStatus err = noErr;
  Float32 maxVolume = 1.0;
  UInt32 size;

  AudioObjectPropertyAddress devCurrDefAddress = {
    kAudioHardwarePropertyDefaultOutputDevice,
    kAudioObjectPropertyScopeGlobal,
    kAudioObjectPropertyElementMaster
  };
  size = sizeof(AudioDeviceID);
  err = AudioObjectGetPropertyData(kAudioObjectSystemObject, &devCurrDefAddress, 0, NULL, &size, &mStashedAudioDeviceID);

  mOutputDeviceID = mStashedAudioDeviceID;

  AudioObjectPropertyAddress volCurrDef1Address = {
    kAudioDevicePropertyVolumeScalar,
    kAudioObjectPropertyScopeOutput,
    1
  };
  size = sizeof(Float32);
  err = AudioObjectGetPropertyData(mStashedAudioDeviceID, &volCurrDef1Address, 0, NULL, &size, &mStashedVolume);

  AudioObjectPropertyAddress volCurrDef2Address = {
    kAudioDevicePropertyVolumeScalar,
    kAudioObjectPropertyScopeOutput,
    2
  };
  size = sizeof(Float32);
  err = AudioObjectGetPropertyData(mStashedAudioDeviceID, &volCurrDef2Address, 0, NULL, &size, &mStashedVolume2);

  gThruEngine2 = new AudioThruEngine;
  gThruEngine2->InitInputDevice(mWavTapDeviceID);
  gThruEngine2->InitOutputDevice(mOutputDeviceID);

  AudioObjectPropertyAddress volSwapWav0Address = {
    kAudioDevicePropertyVolumeScalar,
    kAudioObjectPropertyScopeOutput,
    0
  };
  err = AudioObjectSetPropertyData(mWavTapDeviceID, &volSwapWav0Address, 0, NULL, sizeof(Float32), &maxVolume);

  AudioObjectPropertyAddress volSwapWav1Address = {
    kAudioDevicePropertyVolumeScalar,
    kAudioObjectPropertyScopeOutput,
    1
  };
  err = AudioObjectSetPropertyData(mWavTapDeviceID, &volSwapWav1Address, 0, NULL, sizeof(Float32), &maxVolume);

  AudioObjectPropertyAddress volSwapWav2Address = {
    kAudioDevicePropertyVolumeScalar,
    kAudioObjectPropertyScopeOutput,
    2
  };
  err = AudioObjectSetPropertyData(mWavTapDeviceID, &volSwapWav2Address, 0, NULL, sizeof(Float32), &maxVolume);

//  AudioObjectPropertyAddress volSwapDefAddress = {
//    kAudioDevicePropertyVolumeScalar,
//    kAudioObjectPropertyScopeOutput,
//    1
//  };
//
//  err = AudioObjectSetPropertyData(mStashedAudioDeviceID, &volSwapDefAddress, 0, NULL, sizeof(Float32), &maxVolume);
//
//  AudioObjectPropertyAddress volSwapDef2Address = {
//    kAudioDevicePropertyVolumeScalar,
//    kAudioObjectPropertyScopeOutput,
//    2
//  };
//
//  err = AudioObjectSetPropertyData(mStashedAudioDeviceID, &volSwapDef2Address, 0, NULL, sizeof(Float32), &maxVolume);

  gThruEngine2->Start();

  err = AudioObjectSetPropertyData(kAudioObjectSystemObject, &devCurrDefAddress, 0, NULL, sizeof(AudioDeviceID), &mWavTapDeviceID);
}

- (OSStatus)restoreSystemOutputDevice
{
  OSStatus err = noErr;

  AudioObjectPropertyAddress devAddress = {
    kAudioHardwarePropertyDefaultOutputDevice,
    kAudioObjectPropertyScopeGlobal,
    kAudioObjectPropertyElementMaster
  };
  err = AudioObjectSetPropertyData(kAudioObjectSystemObject, &devAddress, 0, NULL, sizeof(AudioDeviceID), &mStashedAudioDeviceID);

  return err;
}

- (OSStatus)restoreSystemOutputDeviceVolume
{
  OSStatus err = noErr;

  AudioObjectPropertyAddress volAddress = {
    kAudioDevicePropertyVolumeScalar,
    kAudioObjectPropertyScopeOutput,
    1
  };
  err = AudioObjectSetPropertyData(kAudioObjectSystemObject, &volAddress, 0, NULL, sizeof(Float32), &mStashedVolume);

  AudioObjectPropertyAddress vol2Address = {
    kAudioDevicePropertyVolumeScalar,
    kAudioObjectPropertyScopeOutput,
    2
  };
  err = AudioObjectSetPropertyData(kAudioObjectSystemObject, &vol2Address, 0, NULL, sizeof(Float32), &mStashedVolume2);

  return err;
}

OSStatus myHotKeyHandler(EventHandlerCallRef nextHandler, EventRef anEvent, void *userData)
{
  AppController* inUserData = (__bridge AppController*)userData;
  [inUserData toggleRecord];
  return noErr;
}

- (void)bindHotKeys
{
  hotKeyFunction = NewEventHandlerUPP(myHotKeyHandler);
  EventTypeSpec eventType;
  eventType.eventClass = kEventClassKeyboard;
  eventType.eventKind = kEventHotKeyReleased;
  InstallApplicationEventHandler(hotKeyFunction, 1, &eventType, (void *) CFBridgingRetain(self), NULL);

  UInt32 keyCode = 49;
  EventHotKeyRef theRef = NULL;
  EventHotKeyID keyID;
  keyID.signature = 'FOO ';
  keyID.id = 1;
  RegisterEventHotKey(keyCode, cmdKey+controlKey, keyID, GetApplicationEventTarget(), 0, &theRef);
}

-(void)recordStart
{
  NSMenuItem *item = [mMenu itemWithTag:MENU_ITEM_TAG_TOGGLE_RECORD];
  NSArray *argv=[NSArray arrayWithObjects:nil];
  NSTask *task=[[NSTask alloc] init];
  [task setArguments: argv];
  [task setLaunchPath:@"/Applications/WavTap.app/Contents/SharedSupport/record_start"];
  [task launch];
  [item setTitle:@"Stop Recording"];
  mIsRecording = YES;
}

-(void)recordStop
{
  NSMenuItem *item = [mMenu itemWithTag:MENU_ITEM_TAG_TOGGLE_RECORD];
  NSArray *argv=[NSArray arrayWithObjects:nil];
  NSTask *task=[[NSTask alloc] init];
  [task setArguments: argv];
  [task setLaunchPath:@"/Applications/WavTap.app/Contents/SharedSupport/record_stop"];
  [task launch];
  [item setTitle:@"Record"];
  mIsRecording = NO;
}

-(void)toggleRecord
{
  if(mIsRecording){
    [self recordStop];
  } else {
    [self recordStart];
  }
}

- (void)cleanupOnBeforeQuit
{
  if(mIsRecording) [self recordStop];
  if(gThruEngine2) gThruEngine2->Stop();
  [self restoreSystemOutputDevice];
//  [self restoreSystemOutputDeviceVolume];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
  [self cleanupOnBeforeQuit];
}

- (void)doQuit
{
  [self cleanupOnBeforeQuit];
  [NSApp terminate:nil];
}

@end
