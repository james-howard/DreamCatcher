//
//  DCUtil.m
//  DreamCatcher
//
//  Created by James Howard on 9/13/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "DCUtil.h"
#import "DCProperties.h"

@implementation DCUtil

+ (NSStringEncoding)encodingForResponse: (NSURLResponse *)response
{
	CFStringEncoding cfEncoding = kCFStringEncodingInvalidId;
	if([response textEncodingName] != nil) {
		cfEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)[response textEncodingName]);	
	}
	if(cfEncoding == kCFStringEncodingInvalidId) {
		cfEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)[[DCProperties defaults] stringForKey: @"DefaultEncoding"]);
		if(cfEncoding == kCFStringEncodingInvalidId) {
			cfEncoding = kCFStringEncodingISOLatin1;
		}
	}
	return CFStringConvertEncodingToNSStringEncoding(cfEncoding);
}

@end
