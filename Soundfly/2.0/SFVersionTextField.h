//
//  SFVersionTextField.h
//  Soundfly
//
//  Created by JuL on Sat Feb 28 2004.
//  Copyright (c) 2003-2005 abyssoft. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SFVersionTextField : NSTextField
{
	NSArray * _versions;
	int _currentVersionIndex;
}

- (void)setVersions:(NSArray*)inVersions;
- (NSArray*)versions;

- (void)changeVersion;

@end
