//
//  RobotsTxt.h
//  DreamCatcher
//
//  Created by James Howard on 8/11/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RobotsTxt : NSObject {
    NSURL* rootURL;
    // set of substrings of urls that are not allowed to be spidered
    NSMutableSet* blackList;
}

// create a new RobotsTxt and fetch the robots.txt from
// the root url.
- (id)initWithRootURL: (NSURL*)_rootURL;
// create a new RobotsTxt and use the provided robotsTxt rather
// than fetching one from the root url.
- (id)initWithRootURL: (NSURL*)_rootURL
         useRobotsTxt: (NSString*)robotsTxt;

- (BOOL)allowURL: (NSURL*)url;

@end
