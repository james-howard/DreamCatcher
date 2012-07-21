//
//  Spellchecker.m
//  DreamCatcher
//
//  Created by James Howard on 8/13/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "Spellchecker.h"
#import "Page.h"
#import "Spider.h"
#import "DCProperties.h"

static NSMutableDictionary* languagesAndCodes = nil;

@implementation SpellingError

- (id)initWithPage: (Page*)_page
	  rangeOfError: (NSRange)_range
  occurrenceNumber: (int)_occurrence
	   suggestions: (NSArray*)_suggestions
{
	if(self = [super init]) {
		inPage = [_page retain];
		rangeOfError = _range;
		occurrenceNumber = _occurrence;
		ignore = NO;
		suggestions = [_suggestions retain];
	}
	return self;
}
- (void)dealloc
{
	[inPage release];
	[suggestions release];
	[super dealloc];
}

- (Page*)page
{
	return inPage;
}
- (NSRange)range
{
	return rangeOfError;
}
- (int)occurrenceNumber
{
	return occurrenceNumber;
}

- (BOOL)ignore
{
	return ignore;
}
- (void)setIgnore: (BOOL)flag
{
	ignore = flag;
}

- (NSArray*)suggestions
{
	return suggestions;
}

- (NSString*)misspelling
{
	return [[inPage text] substringWithRange: rangeOfError];
}

@end

@implementation Spellchecker

+ (NSDictionary*)checkSiteSpelling: (Spider*)spider
{
	NSSet* addedWords = [[NSSet alloc] initWithArray: [[DCProperties defaults] arrayForKey: @"AddedWords"]];
	NSSpellChecker* checker = [NSSpellChecker sharedSpellChecker];
	NSString* language = [[DCProperties defaults] stringForKey: @"Language"];
	if(language != nil) {
		if(![checker setLanguage: language]) {
			NSLog(@"Couldn't set language to %@, instead using %@", language, [checker language]);
		} else {
			NSLog(@"Spellchecking using language %@", language);
		}
	} else {
		NSLog(@"language was nil");
	}
	NSMutableDictionary* allErrors = [NSMutableDictionary dictionary];
	NSURL* url = nil;
	NSEnumerator* e = [spider urls];
	while(url = [e nextObject]) {
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		NSMutableDictionary* occurrencesDict = [NSMutableDictionary dictionary];
		NSMutableArray* errorArray = [NSMutableArray array];
		Page* page = [spider pageForURL: url];
		int offset = 0;
		while(offset < [[page text] length]) {
			NSAutoreleasePool* pool2 = [[NSAutoreleasePool alloc] init];
			NSRange misspelledRange = [checker checkSpellingOfString: [page text] startingAt: offset];
			if(misspelledRange.location >= [[page text] length] || misspelledRange.location < offset) break;
			offset = misspelledRange.location + misspelledRange.length + 1;
			NSString* misspelled = [[page text] substringWithRange: misspelledRange];
			if([[misspelled stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]] length] <= 0) {
				[pool2 release];
				continue;
			}
			if([addedWords containsObject: misspelled]) {
				[pool2 release];
				continue;
			}
			
			NSNumber* occurrenceNumber = nil;
			if((occurrenceNumber = [occurrencesDict objectForKey: misspelled]) != nil) {
				occurrenceNumber = [NSNumber numberWithInt: [occurrenceNumber intValue] + 1];
			} else {
				occurrenceNumber = [NSNumber numberWithInt: 1];
			}
			[occurrencesDict setObject: occurrenceNumber forKey: misspelled];
			//printf("%s - %s range %s occurrence #%d offset: %d\n", [[url absoluteString] cString], [misspelled cString], [NSStringFromRange(misspelledRange) cString], [occurrenceNumber intValue], offset);
			//printf("\tsuggestions:\n");
			NSArray* suggestions = [checker guessesForWord: misspelled];
			SpellingError* error = [[SpellingError alloc] initWithPage: page 
														  rangeOfError: misspelledRange 
													  occurrenceNumber: [occurrenceNumber intValue] 
														   suggestions: suggestions];
			[errorArray addObject: error];
			[error release];
			[pool2 release];
		}
		if([errorArray count] > 0) {
			[allErrors setObject: errorArray forKey: [page url]];
		} else {
			[allErrors setObject: [NSArray array] forKey: [page url]];
		}
		[pool release];
		
	}
	[addedWords release];
	return allErrors;	
}

+ (void)addWord: (NSString*)word
{
	NSArray* ignoredWords = [[DCProperties defaults] arrayForKey: @"AddedWords"];
	if(ignoredWords == nil) {
		[[DCProperties defaults] setObject: [NSArray arrayWithObject: word] 
									forKey: @"AddedWords"];
	} else {
		NSMutableArray* newWords = [NSMutableArray arrayWithArray: ignoredWords];
		[newWords addObject: word];
		[[DCProperties defaults] setObject: newWords
									forKey: @"AddedWords"];
	}
}
+ (void)unAddWord: (NSString*)word
{
	NSMutableArray* words = [NSMutableArray arrayWithArray: [[DCProperties defaults] arrayForKey: @"AddedWords"]];
	[words removeObject: word];
	[[DCProperties defaults] setObject: words
								forKey: @"AddedWords"];
}

+ (NSDictionary*)languages
{
	if(languagesAndCodes == nil) {
		NSPopUpButton* languagePopUp = [[NSSpellChecker sharedSpellChecker] valueForKey: @"_languagePopUp"];
		NSArray* items = [languagePopUp itemArray];
		languagesAndCodes = [[NSMutableDictionary alloc] initWithCapacity: [items count]];
		for(int i = 0; i < [items count]; i++) {
			id <NSMenuItem> item = [items objectAtIndex: i];
			[languagesAndCodes setValue: [[item representedObject] objectAtIndex: 0] forKey: [item title]];
		}
	}
	return languagesAndCodes;
}

@end
