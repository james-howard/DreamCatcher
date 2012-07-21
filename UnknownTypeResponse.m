//
//  UnknownTypeResponse.m
//  DreamCatcher
//
//  Created by James Howard on 8/8/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "UnknownTypeResponse.h"


@implementation UnknownTypeResponse

- (id)initWithURL: (NSURL*)_url
			 type: (NSString*)_type
{
    if(self = [super initWithURL: _url]) {
		unknownType = [_type retain];
    }
    return self;
}

- (void)dealloc
{
	[super dealloc];
	[unknownType release];
}

- (NSString*)MIMEType
{
    return unknownType;
}


@end
