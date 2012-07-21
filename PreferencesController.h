//
//  PreferencesController.h
//  DreamCatcher
//
//  Created by James Howard on 8/20/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class DSFileTypeDrag;

@interface PreferencesController : NSWindowController {
	IBOutlet id maxSpiderDepthField;
	IBOutlet id addedWordsList;
	IBOutlet id languageChooser;
	IBOutlet id encodingChooser;
	IBOutlet id parserChooser;
	
	IBOutlet DSFileTypeDrag* scriptHandlerWell;
	
	NSMutableArray* wordsList;
}

- (IBAction)addWord: (id)sender;
- (IBAction)removeWord: (id)sender;

- (IBAction)apply: (id)sender;
- (IBAction)cancel: (id)sender;

@end
