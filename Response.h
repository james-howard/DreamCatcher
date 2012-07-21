#import <Cocoa/Cocoa.h>


@interface Response : NSObject {
    NSURL* fromURL;
}

- (id)initWithURL: (NSURL*)_url;

- (NSURL*)url;

@end
