//
//  UnknownTypeResponse.h
//  DreamCatcher
//
//  Created by James Howard on 8/8/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Response.h"

@interface UnknownTypeResponse : Response {
	NSString* unknownType;
}

- (id)initWithURL: (NSURL*)_url
			 type: (NSString*)_unknownType;

- (NSString*)MIMEType;

@end
