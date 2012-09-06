#import <Carbon/Carbon.h>
#import <AudioUnit/AudioUnit.h>
#include <AudioToolbox/AudioFile.h>
#include "AppController.h"
#include "AudioThruEngine.h"
#import <QuartzCore/QuartzCore.h>
#include <iostream>
#include <fstream>

@implementation AppController

AudioThruEngine *mEngine = NULL;
io_connect_t  root_port;

- (id)init
{
  mMenuItemTags = [[NSDictionary alloc] initWithObjectsAndKeys:
                   @"toggleRecord",   @1,
                   @"historyRecord",  @2,
                   @"preferences",    @3,
                   @"quit",           @4,
                   nil];
  mIsRecording = NO;
  mOutputDeviceList = NULL;
  mOutputDeviceID = 0;
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
  [self rebuildDeviceList];
  AudioDeviceList::DeviceList &list = mOutputDeviceList->GetList();
  for (AudioDeviceList::DeviceList::iterator i = list.begin(); i != list.end(); ++i) {
    if (0 == strcmp("WavTap", (*i).mName)) mWavTapDeviceID = (*i).mID;
  }
  [self initConnections];
  [self registerPropertyListeners];
  [self bindHotKeys];
  [self initStatusBar];
  [self buildMenu];
}

- (void)initStatusBar
{
  mSbItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];

  NSImage *image = [NSImage imageNamed:@"menuIcon"];
  [image setTemplate:YES];
  [mSbItem setImage:image];

  NSImage *alternateImage = [NSImage imageNamed:@"menuIconInverse"];
  [alternateImage setTemplate:YES];
  [mSbItem setAlternateImage:alternateImage];

  [mSbItem setToolTip: @"WavTap"];
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

    item = [mMenu addItemWithTitle:@"Save History Buffer" action:@selector(historyRecord) keyEquivalent:@""];
    [item setTarget:self];
    [item setTag:(NSInteger)[mMenuItemTags objectForKey:@"historyRecord"]];
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

  [mMenu setDelegate:(id)self];
}



OSStatus DeviceListenerProc (AudioObjectID inObjectID, UInt32 inNumberAddresses, const AudioObjectPropertyAddress inAddresses[], void*inClientData)
{
  OSStatus err = noErr;
  AppController *app = (AppController *)CFBridgingRelease(inClientData);
  AudioObjectPropertyAddress addr;

  for(int i = 0; i < inNumberAddresses; i++){
    addr = inAddresses[i];
    switch(addr.mSelector) {
      case kAudioDevicePropertyAvailableNominalSampleRates:     { break; }
      case kAudioDevicePropertyClockDomain:                     { break; }
      case kAudioDevicePropertyConfigurationApplication:        { break; }
      case kAudioDevicePropertyDeviceCanBeDefaultDevice:        { break; }
      case kAudioDevicePropertyDeviceCanBeDefaultSystemDevice:  { break; }
      case kAudioDevicePropertyDeviceIsAlive:                   { break; }
      case kAudioDevicePropertyDeviceIsRunning:                 { break; }
      case kAudioDevicePropertyDeviceUID:                       { break; }
      case kAudioDevicePropertyIcon:                            { break; }
      case kAudioDevicePropertyIsHidden:                        { break; }
      case kAudioDevicePropertyLatency:                         { break; }
      case kAudioDevicePropertyModelUID:                        { break; }
      case kAudioDevicePropertyNominalSampleRate:{
        app->mEngine->Stop();
        err = app->mEngine->MatchSampleRates(inObjectID);
        printf("(DeviceListenerProc) MatchSampleRates returned status code: %u \n", err);
        app->mEngine->Start();
        break;
      }
      case kAudioDevicePropertyPreferredChannelLayout:          { break; }
      case kAudioDevicePropertyPreferredChannelsForStereo:      { break; }
      case kAudioDevicePropertyRelatedDevices:                  { break; }
      case kAudioDevicePropertySafetyOffset:                    { break; }
      case kAudioDevicePropertyStreams:                         { break; }
      case kAudioDevicePropertyTransportType:                   { break; }
      case kAudioObjectPropertyControlList:                     { break; }
    }
  }
  return err;
}

- (void)registerPropertyListeners
{
  OSStatus err = noErr;

  AudioObjectPropertyAddress addr = {
    kAudioDevicePropertyNominalSampleRate,
    kAudioObjectPropertyScopeGlobal,
    kAudioObjectPropertyElementMaster
  };
  err = AudioObjectAddPropertyListener(mEngine->GetOutputDeviceID(), &addr, DeviceListenerProc, (__bridge void *)self);

//  addr.mElement = kAudioObjectPropertyScopeWildcard;
//  err = AudioObjectAddPropertyListener(mEngine->GetOutputDeviceID(), &addr, DeviceListenerProc, (__bridge void *)self);
//
//  addr.mElement = kAudioObjectPropertyScopePlayThrough;
//  err = AudioObjectAddPropertyListener(mEngine->GetOutputDeviceID(), &addr, DeviceListenerProc, (__bridge void *)self);
//
//  addr.mElement = kAudioObjectPropertyScopeInput;
//  err = AudioObjectAddPropertyListener(mEngine->GetOutputDeviceID(), &addr, DeviceListenerProc, (__bridge void *)self);
//
//  addr.mElement = kAudioObjectPropertyScopeOutput;
//  err = AudioObjectAddPropertyListener(mEngine->GetOutputDeviceID(), &addr, DeviceListenerProc, (__bridge void *)self);
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

  mEngine = new AudioThruEngine(mWavTapDeviceID, mOutputDeviceID);

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

  mEngine->Start();

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

-(void)launchRecordProcess
{
  mEngine->mOutputDevice.ReloadStreamFormat();
  NSString *bits = @"16"; // TODO: get physical format of output device's stream
//  bits = [NSString stringWithFormat:@"%d", mEngine->mOutputDevice.mFormat.mBitsPerChannel];
  NSTask *task=[[NSTask alloc] init];
  NSArray *argv=[NSArray arrayWithObject:bits];
  [task setArguments: argv];
  [task setLaunchPath:@"/Applications/WavTap.app/Contents/SharedSupport/record.sh"];
  [task launch];
}

-(void)killRecordProcesses
{
  NSArray *argv=[NSArray arrayWithObjects:nil];
  NSTask *task=[[NSTask alloc] init];
  [task setArguments: argv];
  [task setLaunchPath:@"/Applications/WavTap.app/Contents/SharedSupport/kill_recorders.sh"];
  [task launch];
}

-(void)recordStart
{
  NSMenuItem *item = [mMenu itemWithTag:(NSInteger)[mMenuItemTags objectForKey:@"toggleRecord"]];
  [self launchRecordProcess];
  [item setTitle:@"Stop Recording"];
  [mSbItem setImage:[NSImage imageNamed:@"menuIconRecording"]];
  mIsRecording = YES;
}

-(void)recordStop
{
  NSMenuItem *item = [mMenu itemWithTag:(NSInteger)[mMenuItemTags objectForKey:@"toggleRecord"]];
  [self killRecordProcesses];
  [item setTitle:@"Record"];
  NSImage *image = [NSImage imageNamed:@"menuIcon"];
  [image setTemplate:YES];
  [mSbItem setImage:image];
  mIsRecording = NO;
}

-(void)toggleRecord
{
  (mIsRecording) ? [self recordStop] : [self recordStart];
}

-(void)historyRecord
{
  mEngine->Stop();

  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  NSString *dirname = [NSString stringWithFormat:@"%@", documentsDirectory];
  NSDateFormatter *formatter;
  NSString *timestamp;
  formatter = [[NSDateFormatter alloc] init];
  [formatter setDateFormat:@"ddMMyy"];
  timestamp = [formatter stringFromDate:[NSDate date]];
  NSString *absoluteFileName = [NSString stringWithFormat:@"%@/memory_%@.%@", dirname, timestamp, @"wav"];
  const char *fileNameCharBuffer = [absoluteFileName UTF8String];

  mEngine->saveHistoryBuffer(fileNameCharBuffer);
  mEngine->Start();
}

- (void)cleanupOnBeforeQuit
{
  if(mIsRecording) [self recordStop];
  if(mEngine) mEngine->Stop();
  [self restoreSystemOutputDevice];
//  [self restoreSystemOutputDeviceVolume]; // TODO: preserve our eardrums
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
  [self cleanupOnBeforeQuit];
}

- (void)doQuit
{
  [self cleanupOnBeforeQuit];
  [NSApp terminate:nil];
}

@end
