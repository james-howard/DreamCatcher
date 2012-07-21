//
//  DCProperties.m
//  DreamCatcher
//
//  Created by James Howard on 7/6/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "DCProperties.h"


@implementation DCProperties

+ (void)initialize
{
    NSMutableDictionary* ud = [[NSMutableDictionary alloc] init];
    [ud setValue: @"../test_data/" forKey: @"test_data"];
    [ud setValue: @"http://www.excition.com:8080/~fats/dc_tests/" forKey: @"test_url"];
    [ud setValue: @"DreamCatcher 1.2.1" forKey: @"User-Agent"];
	[ud setValue: [NSNumber numberWithInt: 10] forKey: @"SpiderDepth"];
	[ud setValue: [NSNumber numberWithInt: 4] forKey: @"SpiderThreads"];
	[ud setValue: [NSNumber numberWithBool: YES] forKey: @"UseTidy"];
	[ud setValue: @"en" forKey: @"Language"];
	[ud setValue: (NSString*)(CFStringConvertEncodingToIANACharSetName(kCFStringEncodingISOLatin1))
		  forKey: @"DefaultEncoding"];
    [[DCProperties defaults] registerDefaults: ud];
    [ud release];
}

+ (NSUserDefaults *)defaults
{
    return [NSUserDefaults standardUserDefaults];
}

+ (NSString*)version
{
	return @"1.1";
}

@end
