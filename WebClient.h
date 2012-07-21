#import <Cocoa/Cocoa.h>
@class Response;

@protocol WebClient

/** 
 * This method fetches the requested url and returns a Response
 * object for it (Page, 404Response, UnknownResponse, etc)
 * If the page is an html page (Page type) it will fill out the
 * content portion of the page with the text of the page, and
 * it will also parse out all of the html anchors on the page
 * and fill anchorSet with them.
 * Note that this method is expected to block until the operation
 * is fully complete.
 */
- (Response*)fetchAndParsePage: (NSURL*)url
                    setAnchors: (NSMutableSet*)anchorSet;

@end
