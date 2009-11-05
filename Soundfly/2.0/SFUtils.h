//
//  SFUtils.h
//  teleport
//
//  Created by Julien Robert on 11/10/05.
//  Copyright 2005 abyssoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSWorkspace (SFAdditions)

- (void)showPreferencesPaneWithID:(NSString*)prefPaneID async:(BOOL)async;

@end
