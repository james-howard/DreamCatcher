#import <Cocoa/Cocoa.h>

#import "Spider.h"
#import "Page.h"
#import "ProgressListener.h"

@interface CLIProgressListener : NSObject <ProgressListener>

@end

@implementation CLIProgressListener
- (void)fetchingURL: (NSURL*)url
         fromSpider: (Spider*)spider
{
	NSLog(@"fetching url: %@", url);
}
@end

/**
 * A simplistic CLI version of DreamCatcher
 */
int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	int maxSearchDepth = 10;
	const char* arg_url;
	
	/*if(argc < 2) {
		fprintf(stderr, "usage: %s url [max search depth]\n", argv[0]);
		exit(1);
	}*/
	if(argc < 2) {
		arg_url = "http://www.excition.com";
	} else {
		arg_url = argv[1];
	}
	
	if(argc == 3) {
		maxSearchDepth = atoi(argv[2]);
		if(maxSearchDepth <= 0) {
			maxSearchDepth = 10;
		}
	}
	// need to do this to be able to create the spellchecker
	[NSApplication sharedApplication];
	NSSpellChecker *checker = [NSSpellChecker sharedSpellChecker];
	if(checker == nil) {
		checker = [[NSSpellChecker alloc] init];
	}
	if(checker == nil) {
		fprintf(stderr, "couldn't get spellchecker!\n");
		exit(1);
	}
	
	NSURL* startURL = [[NSURL alloc] initWithString: [NSString stringWithCString: arg_url]];
	Spider* spider = [[Spider alloc] initWithBaseURL:  startURL maxSearchDepth: maxSearchDepth];
	CLIProgressListener* listener = [[CLIProgressListener alloc] init];
	[spider addProgressListener: listener];
	[spider blockingRun];
	
	NSURL* url = nil;
	NSEnumerator* e = [spider urls];
	while(url = [e nextObject]) {
		printf("Results for %s\n", [[url absoluteString] cString]);
		Page* page = [spider pageForURL: url];
		// do spell checking
		int offset = 0;
		int num = 1;
		while(offset < [[page text] length]) {
			NSRange misspelledRange = [checker checkSpellingOfString: [page text] startingAt: offset];
			if(misspelledRange.location >= [[page text] length] || misspelledRange.location < offset) break;
			offset = misspelledRange.location + misspelledRange.length + 1;
			NSString* misspelled = [[page text] substringWithRange: misspelledRange];
			if([[misspelled stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]] length] <= 0) {
				continue;
			}
			printf("%d) %s\n", num, [misspelled cString]);
			printf("\tsuggestions:\n");
			NSArray* suggestions = [checker guessesForWord: misspelled];
			NSEnumerator* j = [suggestions objectEnumerator];
			NSString* suggestion;
			while(suggestion = [j nextObject]) {
				printf("\t\t%s\n", [suggestion cString]);
			}
			num++;
		}
		if(num <= 1) {
			printf("\tNo Errors\n");
		}
	}
    
	[listener release];
	[pool release];
	
	//printf("press return to continue ...\n");
	//getchar();
	
    return 0;
}
