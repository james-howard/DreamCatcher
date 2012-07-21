#import <Cocoa/Cocoa.h>
@class Spider;

@protocol ProgressListener

- (void)fetchingURL: (NSURL*)url
         fromSpider: (Spider*)spider;

@end

