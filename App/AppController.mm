#import "AppController.h"
#import <Carbon/Carbon.h>

#include "AudioThruEngine.h"

OSStatus myHotKeyHandler(EventHandlerCallRef nextHandler, EventRef anEvent, void *userData)
{
  AppController* inUserData = (__bridge AppController*)userData;
  
  [inUserData doToggleRecord];
  return noErr;
}

@implementation AppController

EventHandlerUPP hotKeyFunction;
AudioThruEngine *gThruEngine2 = NULL;
Boolean startOnAwake = false;

UInt32 MENU_ITEM_TOGGLE_RECORD_TAG=1;

void CheckErr(OSStatus err)
{
  if (err) {
    NSLog(@"error %-4.4s %i\n", (char *)&err, (int)err);
    throw 1;
  }
}

OSStatus  HardwareListenerProc (AudioHardwarePropertyID inPropertyID,
                                  void* inClientData)
{
  AppController *app = (__bridge AppController *)inClientData;
  NSLog(@"HardwareListenerProc\n");
    switch(inPropertyID) {
      case kAudioHardwarePropertyDevices:
        NSLog(@"kAudioHardwarePropertyDevices\n");
        // An audio device has been added or removed to the system, so lets just start over
        [NSThread detachNewThreadSelector:@selector(refreshDevices) toTarget:app withObject:nil];
        break;
      case kAudioHardwarePropertyIsInitingOrExiting:
        // A UInt32 whose value will be non-zero if the HAL is either in the midst of
        //initializing or in the midst of exiting the process.
        NSLog(@"kAudioHardwarePropertyIsInitingOrExiting\n");
        break;
      case kAudioHardwarePropertySleepingIsAllowed:
        //    A UInt32 where 1 means that the process will allow the CPU to idle sleep
        //    even if there is audio IO in progress. A 0 means that the CPU will not be
        //    allowed to idle sleep. Note that this property won't affect when the CPU is
        //    forced to sleep.
        NSLog(@"kAudioHardwarePropertySleepingIsAllowed\n");
        break;
      case kAudioHardwarePropertyUnloadingIsAllowed:
        //   A UInt32 where 1 means that this process wants the HAL to unload itself
        //   after a period of inactivity where there are no IOProcs and no listeners
        //   registered with any AudioObject.
        NSLog(@"kAudioHardwarePropertyUnloadingIsAllowed\n");
        break;
    }
    return (noErr);
}

OSStatus  DeviceListenerProc (AudioDeviceID inDevice,
                                UInt32 inChannel,
                                Boolean isInput,
                                AudioDevicePropertyID inPropertyID,
                                void* inClientData)
{
  AppController *app = (__bridge AppController *)inClientData;
    switch(inPropertyID) {
      case kAudioDevicePropertyNominalSampleRate:
        if (isInput) {
          if (gThruEngine2->IsRunning() && gThruEngine2->GetInputDevice() == inDevice)
            [NSThread detachNewThreadSelector:@selector(srChanged2ch) toTarget:app withObject:nil];
        }
        else {
          if (inChannel == 0) {
            if (gThruEngine2->IsRunning() && gThruEngine2->GetOutputDevice() == inDevice)
              [NSThread detachNewThreadSelector:@selector(srChanged2chOutput) toTarget:app withObject:nil];
          }
        }
        break;
      case kAudioDevicePropertyDeviceIsAlive:
        break;
      case kAudioDevicePropertyDeviceHasChanged:
        break;
      case kAudioDevicePropertyDataSource:
        if (gThruEngine2->IsRunning() && gThruEngine2->GetOutputDevice() == inDevice)
          [NSThread detachNewThreadSelector:@selector(srChanged2chOutput) toTarget:app withObject:nil];
        break;
      case kAudioDevicePropertyDeviceIsRunning:
        break;
      case kAudioDeviceProcessorOverload:
        break;
      case kAudioDevicePropertyAvailableNominalSampleRates:
        break;
      case kAudioStreamPropertyPhysicalFormat:
        break;
      case kAudioDevicePropertyStreamFormat:
        break;
      case kAudioDevicePropertyStreams:
      case kAudioDevicePropertyStreamConfiguration:
        if (!isInput) {
          if (inChannel == 0) {
            if (gThruEngine2->GetOutputDevice() == inDevice) {
              NSLog(@"non-wavtap device potential # of chnls change\n");
              [NSThread detachNewThreadSelector:@selector(checkNchnls) toTarget:app withObject:nil];
            }
            else // this could be an aggregate device in the middle of constructing, going from/to 0 chans & we need to add/remove to menu
              [NSThread detachNewThreadSelector:@selector(refreshDevices) toTarget:app withObject:nil];
          }
        }
        break;
      default:
        break;
  }
  return noErr;
}

#include <mach/mach_port.h>
#include <mach/mach_interface.h>
#include <mach/mach_init.h>

#include <IOKit/pwr_mgt/IOPMLib.h>
#include <IOKit/IOMessage.h>

io_connect_t  root_port;

void
MySleepCallBack(void * x, io_service_t y, natural_t messageType, void * messageArgument)
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

- (IBAction)suspend
{
  @autoreleasepool {
    mSuspended2chDevice = mCur2chDevice;
    [self outputDeviceSelected:[mMenu itemAtIndex:1]];
  }
}

- (IBAction)resume
{
  //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  if (mSuspended2chDevice) {
    [self outputDeviceSelected:mSuspended2chDevice];
    mCur2chDevice = mSuspended2chDevice;
    mSuspended2chDevice = NULL;
  }
  //[pool release];
}

- (IBAction)srChanged2ch
{
  @autoreleasepool {
    gThruEngine2->Mute();
    OSStatus err = gThruEngine2->MatchSampleRate(true);

    NSMenuItem    *curdev = mCur2chDevice;
    [self outputDeviceSelected:[mMenu itemAtIndex:1]];
    if (err == kAudioHardwareNoError) {
      //usleep(1000);
      [self outputDeviceSelected:curdev];
    }
    gThruEngine2->Mute(false);
  }
}

- (IBAction)srChanged2chOutput
{
  @autoreleasepool {
    gThruEngine2->Mute();
    OSStatus err = gThruEngine2->MatchSampleRate(false);

    // restart devices
    NSMenuItem    *curdev = mCur2chDevice;
    [self outputDeviceSelected:[mMenu itemAtIndex:1]];
    if (err == kAudioHardwareNoError) {
      //usleep(1000);
      [self outputDeviceSelected:curdev];
    }
    gThruEngine2->Mute(false);
  }
}

- (IBAction)checkNchnls
{
  @autoreleasepool {
    if (mNchnls2 != gThruEngine2->GetOutputNchnls())
     {
      NSMenuItem  *curdev = mCur2chDevice;
      [self outputDeviceSelected:[mMenu itemAtIndex:1]];
      //usleep(1000);
      [self outputDeviceSelected:curdev];
    }
  }
}

- (IBAction)refreshDevices
{
  @autoreleasepool {
    [self buildDeviceList];
    [mSbItem setMenu:nil];
    [self buildMenu];
    // make sure that one of our current device's was not removed!
    AudioDeviceID dev = gThruEngine2->GetOutputDevice();
    AudioDeviceList::DeviceList &thelist = mOutputDeviceList->GetList();
    AudioDeviceList::DeviceList::iterator i;
    for (i = thelist.begin(); i != thelist.end(); ++i)
      if ((*i).mID == dev)
        break;
    if (i == thelist.end()) // we didn't find it, turn selection to none
      [self outputDeviceSelected:[mMenu itemAtIndex:1]];
    else
      [self buildRoutingMenu];
  }
}

- (void)InstallListeners;
{
  AudioDeviceList::DeviceList &thelist = mOutputDeviceList->GetList();
  
  for (AudioDeviceList::DeviceList::iterator i = thelist.begin(); i != thelist.end(); ++i) {
    if (0 == strncmp("Soundflower", (*i).mName, strlen("Soundflower"))) {
      verify_noerr(AudioDeviceAddPropertyListener((*i).mID, 0, true, kAudioDevicePropertyNominalSampleRate, DeviceListenerProc,    (void *) CFBridgingRetain(self)));
      verify_noerr(AudioDeviceAddPropertyListener((*i).mID, 0, true, kAudioDevicePropertyStreamConfiguration, DeviceListenerProc,  (void *) CFBridgingRetain(self)));
      verify_noerr(AudioDeviceAddPropertyListener((*i).mID, 0, true, kAudioDevicePropertyDeviceIsAlive, DeviceListenerProc,        (void *) CFBridgingRetain(self)));
      verify_noerr(AudioDeviceAddPropertyListener((*i).mID, 0, true, kAudioDevicePropertyDeviceHasChanged, DeviceListenerProc,     (void *) CFBridgingRetain(self)));
      verify_noerr(AudioDeviceAddPropertyListener((*i).mID, 0, true, kAudioDevicePropertyDeviceIsRunning, DeviceListenerProc,      (void *) CFBridgingRetain(self)));
      verify_noerr(AudioDeviceAddPropertyListener((*i).mID, 0, true, kAudioDeviceProcessorOverload, DeviceListenerProc,            (void *) CFBridgingRetain(self)));
    }
    else {
      verify_noerr(AudioDeviceAddPropertyListener((*i).mID, 0, false, kAudioDevicePropertyNominalSampleRate, DeviceListenerProc,   (void *) CFBridgingRetain(self)));
      verify_noerr(AudioDeviceAddPropertyListener((*i).mID, 0, false, kAudioDevicePropertyStreamConfiguration, DeviceListenerProc, (void *) CFBridgingRetain(self)));
      verify_noerr(AudioDeviceAddPropertyListener((*i).mID, 0, false, kAudioDevicePropertyStreams, DeviceListenerProc,             (void *) CFBridgingRetain(self)));
      verify_noerr(AudioDeviceAddPropertyListener((*i).mID, 0, false, kAudioDevicePropertyDataSource, DeviceListenerProc,          (void *) CFBridgingRetain(self)));
    }
  }
  
  verify_noerr(AudioHardwareAddPropertyListener(kAudioHardwarePropertyDevices, HardwareListenerProc,             (void *) CFBridgingRetain(self)));
  verify_noerr(AudioHardwareAddPropertyListener(kAudioHardwarePropertyIsInitingOrExiting, HardwareListenerProc,  (void *) CFBridgingRetain(self)));
  verify_noerr(AudioHardwareAddPropertyListener(kAudioHardwarePropertySleepingIsAllowed, HardwareListenerProc,   (void *) CFBridgingRetain(self)));
  verify_noerr(AudioHardwareAddPropertyListener(kAudioHardwarePropertyUnloadingIsAllowed, HardwareListenerProc,  (void *) CFBridgingRetain(self)));
}

- (void)RemoveListeners
{
  AudioDeviceList::DeviceList &thelist = mOutputDeviceList->GetList();

  for (AudioDeviceList::DeviceList::iterator i = thelist.begin(); i != thelist.end(); ++i) {
    if (0 == strncmp("Soundflower", (*i).mName, strlen("Soundflower"))) {
      verify_noerr (AudioDeviceRemovePropertyListener((*i).mID, 0, true, kAudioDevicePropertyNominalSampleRate, DeviceListenerProc));
      verify_noerr (AudioDeviceRemovePropertyListener((*i).mID, 0, true, kAudioDevicePropertyStreamConfiguration, DeviceListenerProc));
    }
    else {
      verify_noerr (AudioDeviceRemovePropertyListener((*i).mID, 0, false, kAudioDevicePropertyNominalSampleRate, DeviceListenerProc));
      verify_noerr (AudioDeviceRemovePropertyListener((*i).mID, 0, false, kAudioDevicePropertyStreamConfiguration, DeviceListenerProc));
      verify_noerr (AudioDeviceRemovePropertyListener((*i).mID, 0, false, kAudioDevicePropertyStreams, DeviceListenerProc));
      verify_noerr (AudioDeviceRemovePropertyListener((*i).mID, 0, false, kAudioDevicePropertyDataSource, DeviceListenerProc));
    }
  }
  
   verify_noerr (AudioHardwareRemovePropertyListener(kAudioHardwarePropertyDevices, HardwareListenerProc));
}

- (id)init
{
  mIsRecording = NO;
  mOutputDeviceList = NULL;
  mSoundflower2Device = 0;
  mNchnls2 = 0;
  mSuspended2chDevice = NULL;
  [ self bindHotKeys];

  return self;
}

- (void)dealloc
{
  [self RemoveListeners];
  delete mOutputDeviceList;
}

- (void)buildRoutingMenu
{
  NSMenuItem *hostMenu = m2chMenu;
  UInt32 nchnls = (mNchnls2 = gThruEngine2->GetOutputNchnls());
  AudioDeviceID outDev = (gThruEngine2->GetOutputDevice());
  SEL menuAction = (@selector(routingChanged2ch:));

  for (UInt32 menucount = 0; menucount < 2; menucount++) {
    NSMenuItem *superMenu = [[hostMenu submenu] itemAtIndex:(menucount+3)];

    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Output Device Channel"];
    NSMenuItem *item;

    AudioDeviceList::DeviceList &thelist = mOutputDeviceList->GetList();
    char *name = 0;
    for (AudioDeviceList::DeviceList::iterator i = thelist.begin(); i != thelist.end(); ++i) {
      if ((*i).mID == outDev)
        name = (*i).mName;
    }

    item = [menu addItemWithTitle:@"None" action:menuAction keyEquivalent:@""];
    [item setState:NSOnState];

    char text[128];
    for (UInt32 c = 1; c <= nchnls; ++c) {
      sprintf(text, "%s [%d]", name, (int)c);
      item = [menu addItemWithTitle:[NSString stringWithUTF8String:text] action:menuAction keyEquivalent:@""];
      [item setTarget:self];
      // set check marks according to route map
      if (c == 1 + ((UInt32)gThruEngine2->GetChannelMap(menucount))) {
        [[menu itemAtIndex:0] setState:NSOffState];
        [item setState:NSOnState];
      }
    }
    [superMenu setSubmenu:menu];
  }
}

- (void)setToggleRecordHotKey:(NSString*)keyEquivalent
{
  NSMenuItem *item = [mMenu itemWithTag:MENU_ITEM_TOGGLE_RECORD_TAG];

  [item setKeyEquivalentModifierMask: NSControlKeyMask | NSCommandKeyMask];
  [item setKeyEquivalent:keyEquivalent];
}

- (void)buildMenu
{
  NSMenuItem *item;

  mMenu = [[NSMenu alloc] initWithTitle:@"Main Menu"];

  if (mSoundflower2Device) {
      m2chMenu = [mMenu addItemWithTitle:@"WavTap (2ch)" action:@selector(doNothing) keyEquivalent:@""];
      [m2chMenu setTarget:self];
      NSMenu *submenu = [[NSMenu alloc] initWithTitle:@"2ch submenu"];
      NSMenuItem *bufItem = [submenu addItemWithTitle:@"Buffer Size" action:@selector(doNothing) keyEquivalent:@""];
      m2chBuffer = [[NSMenu alloc] initWithTitle:@"2ch Buffer"];
      item = [m2chBuffer addItemWithTitle:@"64" action:@selector(bufferSizeChanged2ch:) keyEquivalent:@""];
      [item setTarget:self];
      item = [m2chBuffer addItemWithTitle:@"128" action:@selector(bufferSizeChanged2ch:) keyEquivalent:@""];
      [item setTarget:self];
      item = [m2chBuffer addItemWithTitle:@"256" action:@selector(bufferSizeChanged2ch:) keyEquivalent:@""];
      [item setTarget:self];
      item = [m2chBuffer addItemWithTitle:@"512" action:@selector(bufferSizeChanged2ch:) keyEquivalent:@""];
      [item setTarget:self];
      [item setState:NSOnState];
      mCur2chBufferSize = item;
      item = [m2chBuffer addItemWithTitle:@"1024" action:@selector(bufferSizeChanged2ch:) keyEquivalent:@""];
      [item setTarget:self];
      item = [m2chBuffer addItemWithTitle:@"2048" action:@selector(bufferSizeChanged2ch:) keyEquivalent:@""];
      [item setTarget:self];
      [bufItem setSubmenu:m2chBuffer];

      [submenu addItem:[NSMenuItem separatorItem]];

      item = [submenu addItemWithTitle:@"Routing" action:NULL keyEquivalent:@""];
      item = [submenu addItemWithTitle:@"Channel 1" action:@selector(doNothing) keyEquivalent:@""];
      [item setTarget:self];
      item = [submenu addItemWithTitle:@"Channel 2" action:@selector(doNothing) keyEquivalent:@""];
      [item setTarget:self];

      [submenu addItem:[NSMenuItem separatorItem]];

      [[submenu addItemWithTitle:@"Clone to all channels" action:@selector(cloningChanged:) keyEquivalent:@""] setTarget:self];

      [m2chMenu setSubmenu:submenu];

      item = [mMenu addItemWithTitle:@"None" action:@selector(outputDeviceSelected:) keyEquivalent:@""];
      [item setTarget:self];
      [item setState:NSOnState];
      mCur2chDevice = item;

      AudioDeviceList::DeviceList &thelist = mOutputDeviceList->GetList();
      int index = 0;
      for (AudioDeviceList::DeviceList::iterator i = thelist.begin(); i != thelist.end(); ++i) {
          AudioDevice ad((*i).mID, false);
          if (ad.CountChannels())
          {
            item = [mMenu addItemWithTitle:[NSString stringWithUTF8String: (*i).mName] action:@selector(outputDeviceSelected:) keyEquivalent:@""];
            [item setTarget:self];
            mMenuID2[index++] = (*i).mID;
          }
      }
  }
  else {
    item = [mMenu addItemWithTitle:@"Kernel Extension Not Installed" action:NULL keyEquivalent:@""];
    [item setTarget:self];
  }

  [mMenu addItem:[NSMenuItem separatorItem]];


  item = [mMenu addItemWithTitle:@"Record" action:@selector(doToggleRecord) keyEquivalent:@""];
  [item setTarget:self];
  [item setTag:MENU_ITEM_TOGGLE_RECORD_TAG];
  [self setToggleRecordHotKey:@" "];
  [mMenu addItem:[NSMenuItem separatorItem]];


  item = [mMenu addItemWithTitle:@"About..." action:@selector(doAbout) keyEquivalent:@""];
  [item setTarget:self];

  item = [mMenu addItemWithTitle:@"Quit" action:@selector(doQuit) keyEquivalent:@""];
  [item setTarget:self];

  [mSbItem setMenu:mMenu];
}

- (void)buildDeviceList
{
  if (mOutputDeviceList) {
    [ self RemoveListeners];
    delete mOutputDeviceList;
  }

  mOutputDeviceList = new AudioDeviceList(false);
  [ self InstallListeners];

  AudioDeviceList::DeviceList &thelist = mOutputDeviceList->GetList();
  int index = 0;
  for (AudioDeviceList::DeviceList::iterator i = thelist.begin(); i != thelist.end(); ++i, ++index) {
    if (0 == strcmp("WavTap (2ch)", (*i).mName)) {
      mSoundflower2Device = (*i).mID;
      AudioDeviceList::DeviceList::iterator toerase = i;
      i--;
      thelist.erase(toerase);
    }
  }
}

- (void)awakeFromNib
{
  [[NSApplication sharedApplication] setDelegate:self];

  [self buildDeviceList];

  mSbItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];

  [mSbItem setImage:[NSImage imageNamed:@"menuIcon"]];
  [mSbItem setHighlightMode:YES];

  [self buildMenu];

  if (mSoundflower2Device) {
    gThruEngine2 = new AudioThruEngine;
    gThruEngine2->SetInputDevice(mSoundflower2Device);

    gThruEngine2->Start();

    [self buildRoutingMenu];
    [self readGlobalPrefs];
    [self bindHotKeys];
  }

  // ask to be notified on system sleep to avoid a crash
  IONotificationPortRef notify;
  io_object_t anIterator;

  root_port = IORegisterForSystemPower((__bridge void *) self, &notify, MySleepCallBack, &anIterator);
  if (!root_port) {
    NSLog(@"IORegisterForSystemPower failed\n");
  } else {
    CFRunLoopAddSource(CFRunLoopGetCurrent(), IONotificationPortGetRunLoopSource(notify), kCFRunLoopCommonModes);
  }
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

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
  [self recordStop];

  if (gThruEngine2) {
    gThruEngine2->Stop();
  }

  if (mSoundflower2Device) {
    [self writeGlobalPrefs];
  }
}

- (IBAction)bufferSizeChanged2ch:(id)sender
{
  UInt32 val = [m2chBuffer indexOfItem:sender];
  UInt32 size = 64 << val;
  gThruEngine2->SetBufferSize(size);

  [mCur2chBufferSize setState:NSOffState];
  [sender setState:NSOnState];
  mCur2chBufferSize = sender;
}

- (IBAction)cloningChanged:(id)sender
{
  [sender setState:([sender state]==NSOnState) ? NSOffState : NSOnState];
  gThruEngine2->SetCloneChannels([sender state]==NSOnState);
  [self writeDevicePrefs:YES];
}

- (IBAction)cloningChanged:(id)sender cloneChannels:(bool)clone
{
  gThruEngine2->SetCloneChannels(clone);
  [sender setState:(clone ? NSOnState : NSOffState)];
}

- (IBAction)routingChanged2ch:(id)outDevChanItem
{
  NSMenu *outDevMenu = [outDevChanItem menu];
  NSMenu *superMenu = [outDevMenu supermenu];
  int sfChan = [superMenu indexOfItemWithSubmenu:outDevMenu] - 3;
  int outDevChan = [outDevMenu indexOfItem:outDevChanItem];
  gThruEngine2->SetChannelMap(sfChan, outDevChan-1);

  for (int i = 0; i < [outDevMenu numberOfItems]; i++) {
    [[outDevMenu itemAtIndex:i] setState:NSOffState];
  }

  [outDevChanItem setState:NSOnState];
  [self writeDevicePrefs:YES];
}

- (IBAction)outputDeviceSelected:(id)sender
{
  int val = [mMenu indexOfItem:sender];
  val -= 2;

  // if 'None' was selected, our val will be == -1, which will return a NULL
  // device from the list, which is what we want anyway, and seems to work
  // here -- probably should check to see if there are any potential problems
  // and handle this more properly
  gThruEngine2->SetOutputDevice( (val < 0 ? kAudioDeviceUnknown : mMenuID2[val]) );
  [mCur2chDevice setState:NSOffState];
  [sender setState:NSOnState];
  mCur2chDevice = sender;
  [self readDevicePrefs:YES];
  [self buildRoutingMenu];
}

- (void)doNothing { }

- (void)readGlobalPrefs
{
  CFStringRef strng  = (CFStringRef) CFPreferencesCopyAppValue(CFSTR("2ch Output Device"), kCFPreferencesCurrentApplication);
  if (strng) {
    char name[64];
    CFStringGetCString(strng, name, 64, kCFStringEncodingMacRoman);
    NSMenuItem *item = [mMenu itemWithTitle:[NSString stringWithUTF8String:name]];
    if (item)
      [self outputDeviceSelected:item];
  }

  CFNumberRef num = (CFNumberRef) CFPreferencesCopyAppValue(CFSTR("2ch Buffer Size"), kCFPreferencesCurrentApplication);
  if (num) {
    UInt32 val;
    CFNumberGetValue(num, kCFNumberLongType, &val);
//    CFRelease(num);

    switch (val) {
      case 64:
        [self bufferSizeChanged2ch:[m2chBuffer itemAtIndex:0]];
        break;
      case 128:
        [self bufferSizeChanged2ch:[m2chBuffer itemAtIndex:1]];
        break;
      case 256:
        [self bufferSizeChanged2ch:[m2chBuffer itemAtIndex:2]];
        break;
      case 1024:
        [self bufferSizeChanged2ch:[m2chBuffer itemAtIndex:4]];
        break;
      case 2048:
        [self bufferSizeChanged2ch:[m2chBuffer itemAtIndex:5]];
        break;
      case 512:
      default:
        [self bufferSizeChanged2ch:[m2chBuffer itemAtIndex:3]];
        break;
    }
  }
}

- (void)writeGlobalPrefs
{
  CFStringRef cfstr = CFStringCreateWithCString(kCFAllocatorSystemDefault, [[mCur2chDevice title] UTF8String], kCFStringEncodingMacRoman);
  CFPreferencesSetAppValue(CFSTR("2ch Output Device"), cfstr, kCFPreferencesCurrentApplication);
  CFRelease(cfstr);

  UInt32 val = 64 << [m2chBuffer indexOfItem:mCur2chBufferSize];
  CFNumberRef number = CFNumberCreate(kCFAllocatorSystemDefault, kCFNumberIntType, &val);
  CFPreferencesSetAppValue(CFSTR("2ch Buffer Size"), number, kCFPreferencesCurrentApplication);
  CFRelease(number);

  CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication);
}

- (CFStringRef)formDevicePrefName:(BOOL)is2ch
{
  NSString *routingTag = @" [2ch Routing]";
  NSString *deviceName  = [mCur2chDevice title];
  return CFStringCreateWithCString(kCFAllocatorSystemDefault, [[deviceName stringByAppendingString:routingTag] UTF8String], kCFStringEncodingMacRoman);
}

- (void)readDevicePrefs:(BOOL)is2ch
{
  AudioThruEngine  *thruEng = gThruEngine2;
  int numChans = 2;
  CFStringRef arrayName = [self formDevicePrefName:is2ch];
  CFArrayRef mapArray = (CFArrayRef) CFPreferencesCopyAppValue(arrayName, kCFPreferencesCurrentApplication);

  if (mapArray) {
    for (int i = 0; i < numChans; i++) {
      CFNumberRef num = (CFNumberRef)CFArrayGetValueAtIndex(mapArray, i);
      if (num) {
        UInt32 val;
        CFNumberGetValue(num, kCFNumberLongType, &val);
        thruEng->SetChannelMap(i, val-1);
        //CFRelease(num);
      }
    }
    //CFRelease(mapArray);
  }
  else { // set to default
    for (int i = 0; i < numChans; i++)
      thruEng->SetChannelMap(i, i);
  }

  //CFRelease(arrayName);

  if (is2ch) {
    CFBooleanRef clone = (CFBooleanRef)CFPreferencesCopyAppValue(CFSTR("Clone channels"), kCFPreferencesCurrentApplication);
    NSMenuItem* item = [[m2chMenu submenu] itemWithTitle:@"Clone to all channels"];
      if (clone && item) {
        [self cloningChanged:item cloneChannels:CFBooleanGetValue(clone)];
        CFRelease(clone);
      }
      else {
        thruEng->SetCloneChannels(false);
      }
  }
}

- (void)writeDevicePrefs:(BOOL)is2ch
{
  AudioThruEngine  *thruEng = gThruEngine2;
  int numChans = 2;
  CFNumberRef map[64];

  CFStringRef arrayName = [self formDevicePrefName:is2ch];

  for (int i = 0; i < numChans; i++)
  {
    UInt32 val = thruEng->GetChannelMap(i) + 1;
    map[i] = CFNumberCreate(kCFAllocatorSystemDefault, kCFNumberIntType, &val);
  }

  CFArrayRef mapArray = CFArrayCreate(kCFAllocatorSystemDefault, (const void**)&map, numChans, NULL);
  CFPreferencesSetAppValue(arrayName, mapArray, kCFPreferencesCurrentApplication);
  //CFRelease(mapArray);

  //for (int i = 0; i < numChans; i++)
  //  CFRelease(map[i]);
  //CFRelease(arrayName);

  if(is2ch){
    char cloneValue = thruEng->CloneChannels();
    CFNumberRef clone = (CFNumberRef)CFNumberCreate(kCFAllocatorSystemDefault, kCFNumberCharType, &cloneValue);
    CFPreferencesSetAppValue(CFSTR("Clone channels"),
                 clone,
                 kCFPreferencesCurrentApplication);
    CFRelease(clone);
  }

  CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication);
}

-(void)recordStart
{
  NSMenuItem *item = [mMenu itemWithTag:MENU_ITEM_TOGGLE_RECORD_TAG];

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
  NSMenuItem *item = [mMenu itemWithTag:MENU_ITEM_TOGGLE_RECORD_TAG];

  NSArray *argv=[NSArray arrayWithObjects:nil];
  NSTask *task=[[NSTask alloc] init];
  [task setArguments: argv];
  [task setLaunchPath:@"/Applications/WavTap.app/Contents/SharedSupport/record_stop"];
  [task launch];
  [item setTitle:@"Record"];
  mIsRecording = NO;
}

-(void)doToggleRecord
{
  if(mIsRecording){
    [self recordStop];
  } else {
    [self recordStart];
  }
}

-(void)doAbout
{
  [mAboutController doAbout];
}

- (void)doQuit
{
  [self recordStop];
  [NSApp terminate:nil];
}

@end
