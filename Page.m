#import "Page.h"


@implementation Page

- (id)initWithURL: (NSURL *)_url
		 pageText: (NSString *)_fullText
{
	if(self = [super initWithURL: _url]) {
		fullText = [_fullText retain];
	}
	return self;
}

- (void)dealloc
{
	[fullText release];
	[super dealloc];
}

- (NSString *)text
{
	return fullText;
}

- (NSComparisonResult)compare: (Page*)other
{
	return [[[self url] absoluteString] compare: [[other url] absoluteString]];
}

@end
