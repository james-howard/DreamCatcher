/**
 * A WebClient built using the HTTP handling classes in Foundation.
 */

#import <Cocoa/Cocoa.h>
#import "WebClient.h"

@protocol ContentParser

- (BOOL)canHandleType: (NSString*)mimeType;

- (Response*)parseContent: (NSData*)content
			 fromResponse: (NSURLResponse*)response
			   setAnchors: (NSMutableSet*)anchorSet;

@end

@interface FoundationWebClient : NSObject <WebClient> {
	// array of id<ContentParser>
	NSMutableArray* contentParsers;
}

- (Response*)fetchAndParsePage: (NSURL*)url
                    setAnchors: (NSMutableSet*)anchorSet;

- (void)registerContentParser: (id<ContentParser>)parser;

@end
