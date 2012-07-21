#import <Cocoa/Cocoa.h>
@class Page;
@class Spider;

@interface SpellingError : NSObject {
	Page* inPage;
	NSRange rangeOfError;
	int occurrenceNumber;
	BOOL ignore;
	NSArray* suggestions;
}

- (id)initWithPage: (Page*)_page
	  rangeOfError: (NSRange)_range
  occurrenceNumber: (int)_occurrence
	   suggestions: (NSArray*)_suggestions;

- (NSString*)misspelling;

- (Page*)page;
- (NSRange)range;
- (int)occurrenceNumber;

- (BOOL)ignore;
- (void)setIgnore: (BOOL)flag;

- (NSArray*)suggestions;

@end

@interface Spellchecker : NSObject {

}

// returns a Dictionary wheree
// NSURL -> SpellingError
+ (NSDictionary*)checkSiteSpelling: (Spider*)spider;

+ (void)addWord: (NSString*)word;
+ (void)unAddWord: (NSString*)word;

// get a list of all the languages the spellchecker can use
// Language Name => Language Code
+ (NSDictionary*)languages;

@end
