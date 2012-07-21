//
//  ErrorResponse.h
//  DreamCatcher
//
//  Created by James Howard on 7/13/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Response.h"


@interface ErrorResponse : Response {
    int errorCode;
}

- (id)initWithURL: (NSURL*)_url
        errorCode: (int)_errorCode;

- (int)errorCode;

@end
