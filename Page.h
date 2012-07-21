#import <Cocoa/Cocoa.h>
#import "Response.h"

@interface Page : Response {

	NSString* fullText;
	
}

- (id)initWithURL: (NSURL *)_url
		 pageText: (NSString *)_fullText;

- (NSString *)text;

@end
