//
//  ErrorResponse.m
//  DreamCatcher
//
//  Created by James Howard on 7/13/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "ErrorResponse.h"


@implementation ErrorResponse

- (id)initWithURL: (NSURL*)_url
        errorCode: (int)_errorCode
{
    if(self = [super initWithURL: _url]) {
        errorCode = _errorCode;
    }
    return self;
}

- (int)errorCode
{
    return errorCode;
}

@end
