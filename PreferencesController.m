//
//  PreferencesController.m
//  DreamCatcher
//
//  Created by James Howard on 8/20/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "PreferencesController.h"
#import "DCProperties.h"
#import "Spellchecker.h"
#import "DSFileTypeDrag.h"

@interface PreferencesController (private)

- (void)populateContentEncodings;

@end

@implementation PreferencesController

/*- (void)windowWillLoad
{
	wordsList = [[NSMutableArray alloc] initWithArray: [[DCProperties defaults] arrayForKey: @"AddedWords"]];
	[super windowWillLoad];
}*/

- (void)windowDidLoad
{
	[super windowDidLoad];
	[scriptHandlerWell setRequiredExtension: @"scpt"];
	[maxSpiderDepthField setIntValue: [[DCProperties defaults] integerForKey: @"SpiderDepth"]];
	[languageChooser removeAllItems];
	[languageChooser addItemsWithTitles: [[Spellchecker languages] allKeys]];
	NSArray* titles = [[Spellchecker languages] allKeysForObject: [[DCProperties defaults] stringForKey: @"Language"]];
	if([titles count] > 0)
		[languageChooser selectItemWithTitle: [titles objectAtIndex: 0]];
	[self populateContentEncodings];
}

- (IBAction)showWindow: (id)sender
{
	// load the stuff out of the preferences
	[super showWindow: sender];
	[scriptHandlerWell setPath: [[DCProperties defaults] stringForKey: @"ScriptHandler"]];
	[wordsList release];
	wordsList = [[NSMutableArray alloc] initWithArray: [[DCProperties defaults] arrayForKey: @"AddedWords"]];
	[wordsList sortUsingSelector: @selector(caseInsensitiveCompare:)];
	[addedWordsList reloadData];
	[maxSpiderDepthField setIntValue: [[DCProperties defaults] integerForKey: @"SpiderDepth"]];
	[languageChooser removeAllItems];
	[languageChooser addItemsWithTitles: [[Spellchecker languages] allKeys]];
	NSArray* titles = [[Spellchecker languages] allKeysForObject: [[DCProperties defaults] stringForKey: @"Language"]];
	if([titles count] > 0)
		[languageChooser selectItemWithTitle: [titles objectAtIndex: 0]];	
	if([[DCProperties defaults] boolForKey: @"UseTidy"]) {
		[parserChooser selectItemWithTitle: @"Tidy"];
	} else {
		[parserChooser selectItemWithTitle: @"DreamCatcher"];
	}
	[self populateContentEncodings];
}

- (void)populateContentEncodings
{
	[encodingChooser removeAllItems];
	NSMutableArray* encodingsArray = [NSMutableArray array];
	for(const CFStringEncoding* encodings = CFStringGetListOfAvailableEncodings();
		*encodings != kCFStringEncodingInvalidId; encodings++) {
		NSString* encodingName = (NSString*)CFStringConvertEncodingToIANACharSetName(*encodings);
		if(encodingName == nil) continue;
		[encodingsArray addObject: encodingName];
	}
	[encodingsArray sortUsingSelector: @selector(caseInsensitiveCompare:)];
	[encodingChooser addItemsWithTitles: encodingsArray];
	NSString* currentValue = [[DCProperties defaults] stringForKey: @"DefaultEncoding"];
	if(currentValue != nil) {
		[encodingChooser selectItemWithTitle: currentValue];
	}
}

- (IBAction)addWord: (id)sender
{
	[wordsList addObject: @" "];
	[wordsList sortUsingSelector: @selector(caseInsensitiveCompare:)];
	[addedWordsList reloadData];
	[addedWordsList selectRowIndexes: [NSIndexSet indexSetWithIndex: 0] 
				byExtendingSelection: NO];
	[addedWordsList editColumn: 0 row: 0 withEvent: nil select: YES];
}

- (IBAction)removeWord: (id)sender
{
	int index = [addedWordsList selectedRow];
	if(index >= 0 && index <= [wordsList count]) {
		[wordsList removeObjectAtIndex: index];
		[addedWordsList reloadData];
	}
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [wordsList count];
}

- (void)tableView:(NSTableView *)aTableView 
   setObjectValue:(id)anObject 
   forTableColumn:(NSTableColumn *)aTableColumn 
			  row:(int)rowIndex
{
	NSString* word = [(NSString*)anObject stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
	if([word length] > 0) {
		[wordsList replaceObjectAtIndex: rowIndex withObject: anObject];
	} else {
		[wordsList removeObjectAtIndex: rowIndex];
	}
	[wordsList sortUsingSelector: @selector(caseInsensitiveCompare:)];
	[addedWordsList reloadData];
	[addedWordsList abortEditing];
}

- (id)tableView:(NSTableView *)aTableView
    objectValueForTableColumn:(NSTableColumn *)aTableColumn
			row:(int)rowIndex
{
	if(rowIndex >= 0 && rowIndex < [wordsList count]) {
		return [wordsList objectAtIndex: rowIndex];
	} else {
		return nil;
	}
}

- (IBAction)apply: (id)sender
{
	[wordsList removeObject: @" "];
	[[DCProperties defaults] setObject: wordsList forKey: @"AddedWords"];
	int spiderDepth = [maxSpiderDepthField intValue];
	if(spiderDepth <= 0) spiderDepth = 10;
	[[DCProperties defaults] setInteger: spiderDepth forKey: @"SpiderDepth"];
	NSString* languageTitle = [[languageChooser selectedItem] title];
	NSString* languageCode = [[Spellchecker languages] objectForKey: languageTitle];
	NSLog(@"setting language to %@ => %@", languageTitle, languageCode);
	[[DCProperties defaults] setObject: languageCode forKey: @"Language"];
	[[DCProperties defaults] setObject: [[encodingChooser selectedItem] title] forKey: @"DefaultEncoding"];
	[[DCProperties defaults] setObject: [scriptHandlerWell path] forKey: @"ScriptHandler"];
	[[DCProperties defaults] setBool: [[parserChooser titleOfSelectedItem] isEqualToString: @"Tidy"] forKey: @"UseTidy"];
	[[DCProperties defaults] synchronize];
	[self close];
}
- (IBAction)cancel: (id)sender
{
	[self close];
}

@end
