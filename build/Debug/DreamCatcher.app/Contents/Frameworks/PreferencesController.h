//
//  PreferencesController.h
//  DreamCatcher
//
//  Created by James Howard on 8/20/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PreferencesController : NSWindowController {
	IBOutlet id maxSpiderDepthField;
	IBOutlet id addedWordsList;
	
	NSMutableArray* wordsList;
}

- (IBAction)addWord: (id)sender;
- (IBAction)removeWord: (id)sender;

- (IBAction)apply: (id)sender;
- (IBAction)cancel: (id)sender;

@end
