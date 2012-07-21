//
//  TidyHTMLParser.h
//  DreamCatcher
//
//  Created by James Howard on 4/17/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FoundationWebClient.h"

@interface TidyHTMLParser : NSObject <ContentParser> {

}

- (BOOL)canHandleType: (NSString*)mimeType;

- (Response*)parseContent: (NSData*)content
			 fromResponse: (NSURLResponse*)response
			   setAnchors: (NSMutableSet*)anchorSet;


@end
