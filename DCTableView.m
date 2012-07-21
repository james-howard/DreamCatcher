//
//  DCTableView.m
//  DreamCatcher
//
//  Created by James Howard on 8/20/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "DCTableView.h"


@implementation DCTableView

- (void)textDidEndEditing:(NSNotification *)notification; 
{ 
	if ([[[notification userInfo] objectForKey:@"NSTextMovement"] 
		intValue] == NSReturnTextMovement) { 
		/* This is ugly, but just about the only way to do it. 
			NSTableView is determined to select and edit something else, even the 
			text field that it just finished editing, unless we mislead it about 
			what key was pressed to end editing. 
		*/
		NSMutableDictionary *newUserInfo; 
		NSNotification *newNotification; 
		
		newUserInfo = [NSMutableDictionary 
dictionaryWithDictionary:[notification userInfo]]; 
		[newUserInfo setObject:[NSNumber 
numberWithInt:NSIllegalTextMovement] forKey:@"NSTextMovement"]; 
		newNotification = [NSNotification 
notificationWithName:[notification name] object:[notification object] 
			userInfo:newUserInfo]; 
		[super textDidEndEditing:newNotification]; 
		
		// For some reason we lose firstResponder status when when we do the above. 
			[[self window] makeFirstResponder:self]; 
	} else { 
		[super textDidEndEditing:notification]; 
	} 
} 

@end
