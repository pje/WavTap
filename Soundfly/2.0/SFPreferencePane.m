//
//  SFPreferencePane.m
//  Soundfly
//
//  Created by Julien Robert on 15/02/08.
//  Copyright 2008 abyssoft. All rights reserved.
//

#import "SFPreferencePane.h"

#import "SFPreferencesManager.h"
#import "SFCommunicationManager.h"
#import "SFDaemonManager.h"

#import "SFVersionTextField.h"

static NSImage * kSFOfflineImage = nil;
static NSImage * kSFOnlineImage = nil;
static NSImage * kSFProblemImage = nil;

@interface SFPreferencePane ()

- (void)_checkDaemon;

@end

@implementation SFPreferencePane

+ (void)initialize
{
    if(self == [SFPreferencePane class]) {
        [self setKeys:[NSArray arrayWithObject:@"senderStatus"] triggerChangeNotificationsForDependentKey:@"senderConnectionImage"];
        [self setKeys:[NSArray arrayWithObject:@"senderStatus"] triggerChangeNotificationsForDependentKey:@"senderConnectionTooltip"];
        
        [self setKeys:[NSArray arrayWithObject:@"receiverStatus"] triggerChangeNotificationsForDependentKey:@"receiverConnectionImage"];
        [self setKeys:[NSArray arrayWithObject:@"receiverStatus"] triggerChangeNotificationsForDependentKey:@"receiverConnectionTooltip"];
        
        NSBundle * prefPaneBundle = [NSBundle bundleForClass:[self class]];
        NSString * offlineImagePath = [prefPaneBundle pathForResource:@"offline" ofType:@"tiff"];
        kSFOfflineImage = [[NSImage alloc] initWithContentsOfFile:offlineImagePath];
        NSString * onlineImagePath = [prefPaneBundle pathForResource:@"online" ofType:@"tiff"];
        kSFOnlineImage = [[NSImage alloc] initWithContentsOfFile:onlineImagePath];
        NSString * problemImagePath = [prefPaneBundle pathForResource:@"problem" ofType:@"tiff"];
        kSFProblemImage = [[NSImage alloc] initWithContentsOfFile:problemImagePath];
    }
}

- (BOOL)isLeopardOrBetter
{
    SInt32 MacVersion;
	if(Gestalt(gestaltSystemVersion, &MacVersion) == noErr)
		return (MacVersion >= 0x1050);
	else
		return NO;
}

- (void)mainViewDidLoad
{
    if([self isLeopardOrBetter]) {
		NSView * mainView = [self mainView];
		NSRect frame = [mainView frame];
		frame.size.width = 668.0;
		[mainView setFrame:frame];
	}
    
    [[SFDaemonManager manager] setDelegate:self];
    [[SFCommunicationManager sharedManager] setDelegate:self];
    [_aboutWindow setDelegate:self];
}

- (void)willSelect
{
	[self _checkDaemon];
    [[SFCommunicationManager sharedManager] startListeners];
    [[SFCommunicationManager sharedManager] requestStatusUpdate];
}

- (void)willUnselect
{
    [[SFCommunicationManager sharedManager] stopListeners];
}

- (BOOL)active
{
	return _active;
}

- (void)setActive:(BOOL)active
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_checkDaemon) object:nil];
	[self performSelector:@selector(_checkDaemon) withObject:nil afterDelay:1.0];
	
	_active = active;
	
	if(active) {
		[[SFDaemonManager manager] launchDaemonIfNeeded];
		[[SFDaemonManager manager] registerDaemonIfNeeded];
	}
	else {
		[[SFDaemonManager manager] terminateDaemon];
		[[SFDaemonManager manager] unregisterDaemon];
	}
}

- (void)_checkDaemon
{
	if(_active != [[SFDaemonManager manager] isDaemonRunning]) {
		[self willChangeValueForKey:@"active"];
		_active = !_active;
		[self didChangeValueForKey:@"active"];
	}
}

- (void)deactivate
{
	[self setActive:NO];
}

- (void)daemonDidDie
{
	if(_active) {
		[self willChangeValueForKey:@"active"];
		_active = NO;
		[self didChangeValueForKey:@"active"];
	}
}

- (SFPreferencesManager*)prefs
{
	return [SFPreferencesManager sharedPreferencesManager];
}


#pragma mark -
#pragma mark Connection status

- (void)moduleWithID:(NSString*)moduleID didChangeParameter:(AudioUnitParameterID)parameterID toValue:(Float32)value
{
    if(parameterID == kAUNetReceiveParam_Status) {
        int status = (int)value;
        
        if([moduleID isEqualToString:kSFModuleSenderID]) {
            [self willChangeValueForKey:@"senderStatus"];
            _senderStatus = status;
            [self didChangeValueForKey:@"senderStatus"];
        }
        else if([moduleID isEqualToString:kSFModuleReceiverID]) {
            [self willChangeValueForKey:@"receiverStatus"];
            _receiverStatus = status;
            [self didChangeValueForKey:@"receiverStatus"];
            
        }
        NSLog(@"%@ change status to %d", moduleID, (int)value);
    }
}

- (NSImage*)_imageForStatus:(int)status
{
    NSImage * image = nil;
    
    switch(status) {
        case kAUNetStatus_NotConnected:
            image = kSFOfflineImage;
            break;
        case kAUNetStatus_Connected:
            image = kSFOnlineImage;
            break;
        case kAUNetStatus_Overflow:
            image = kSFProblemImage;
            break;
        case kAUNetStatus_Underflow:
            image = kSFProblemImage;
            break;
        case kAUNetStatus_Connecting:
            image = kSFOfflineImage;
            break;
        case kAUNetStatus_Listening:
            image = kSFOfflineImage;
            break;
        default:
            image = kSFOfflineImage;
            break;
    }
    
    return image;    
}

- (NSImage*)receiverConnectionImage
{
    return [self _imageForStatus:_receiverStatus];
}

- (NSString*)receiverConnectionTooltip
{
    switch(_receiverStatus) {
        case kAUNetStatus_Connected:
            return NSLocalizedStringFromTableInBundle(@"Playing remote audio.", nil, [NSBundle bundleForClass:[self class]], nil);
        case kAUNetStatus_Overflow:
            return NSLocalizedStringFromTableInBundle(@"Overflow with remote audio.", nil, [NSBundle bundleForClass:[self class]], nil);
        case kAUNetStatus_Underflow:
            return NSLocalizedStringFromTableInBundle(@"Underflow with remote audio.", nil, [NSBundle bundleForClass:[self class]], nil);
        case kAUNetStatus_Connecting:
            return NSLocalizedStringFromTableInBundle(@"Connecting.", nil, [NSBundle bundleForClass:[self class]], nil);
        case kAUNetStatus_Listening:
        case kAUNetStatus_NotConnected:
            return NSLocalizedStringFromTableInBundle(@"Not connected.", nil, [NSBundle bundleForClass:[self class]], nil);
        default:
            return nil;
    }
}

- (NSImage*)senderConnectionImage
{
    return [self _imageForStatus:_senderStatus];
}

- (NSString*)senderConnectionTooltip
{
    switch(_senderStatus) {
        case kAUNetStatus_Connected:
            return NSLocalizedStringFromTableInBundle(@"Streaming audio.", nil, [NSBundle bundleForClass:[self class]], nil);
        case kAUNetStatus_Overflow:
            return NSLocalizedStringFromTableInBundle(@"Overflow with audio stream.", nil, [NSBundle bundleForClass:[self class]], nil);
        case kAUNetStatus_Underflow:
            return NSLocalizedStringFromTableInBundle(@"Underflow with audio stream.", nil, [NSBundle bundleForClass:[self class]], nil);
        case kAUNetStatus_Connecting:
            return NSLocalizedStringFromTableInBundle(@"Connecting.", nil, [NSBundle bundleForClass:[self class]], nil);
        case kAUNetStatus_Listening:
        case kAUNetStatus_NotConnected:
            return NSLocalizedStringFromTableInBundle(@"Not connected.", nil, [NSBundle bundleForClass:[self class]], nil);
        default:
            return nil;
    }
}


#pragma mark -
#pragma mark About

- (IBAction)showAboutSheet:(id)sender
{
    if([[_versionTextField versions] count] == 0) {
        NSBundle * mainBundle = [NSBundle bundleForClass:[self class]];
        NSDictionary * infoDict = [mainBundle localizedInfoDictionary];
        if(infoDict == nil) {
            infoDict = [mainBundle infoDictionary];
        }
        NSString * daemonPath = [mainBundle pathForResource:SOUNDFLY_DAEMON ofType:@"app"];
        NSBundle * daemonBundle = [NSBundle bundleWithPath:daemonPath];
        NSDictionary * daemonInfoDict = [daemonBundle infoDictionary];
        
        NSString * publicVersion = [infoDict objectForKey:@"CFBundleGetInfoString"];
        NSString * buildVersion = [daemonInfoDict objectForKey:@"CFBundleVersion"];
        //NSString * translationInfo = [infoDict objectForKey:@"TPTranslationInfoString"];
        [_versionTextField setVersions:[NSArray arrayWithObjects:publicVersion, [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Build %@", nil, [NSBundle bundleForClass:[self class]], nil), buildVersion], nil]];
        
    }

	[NSApp beginSheet:_aboutWindow modalForWindow:[[self mainView] window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

- (void)closeAboutSheet
{
	//DebugLog(@"closeAboutSheet");
	[NSApp endSheet:_aboutWindow];
	[_aboutWindow orderOut:nil];
}

@end
