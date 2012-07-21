#import "Response.h"


@implementation Response

- (id)initWithURL: (NSURL*)_url
{
    if(self = [super init]) {
        fromURL = [_url retain];
    }
    return self;
}
- (void)dealloc
{
    [super dealloc];
    [fromURL release];
}

- (NSURL*)url
{
    return fromURL;
}

@end
