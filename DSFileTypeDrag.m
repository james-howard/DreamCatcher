//
//  DSFileTypeDrag.m
//  DirectSync
//
//  Created by James Howard on Sun Jan 26 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "DSFileTypeDrag.h"


@implementation DSFileTypeDrag

- (id)initWithFrame: (NSRect)rect
{
    if(self = [super initWithFrame: rect]) {
        acceptedTypes = [[NSArray alloc] init];
		[self setImage: [self defaultIcon]];
    }
    return self;
}

- (void)setRequiredExtension: (NSString *)ext
{
	[self setAcceptedTypes: [NSArray arrayWithObject: ext]];
}
- (NSString *)requiredExtension
{
    if([acceptedTypes count] > 0)
		return [acceptedTypes objectAtIndex: 0];
	else 
		return nil;
}

- (void)setAcceptedTypes: (NSArray *)types
{
    [types retain];
    [acceptedTypes release];
    acceptedTypes = types;
	
	[self setImage: [self defaultIcon]];
	
}
- (NSArray *)acceptedTypes
{
    return acceptedTypes;
}

- (BOOL)_takeValueFromPasteboard: (NSPasteboard *)pb operationName:(NSString *)op
{
    NSArray *filenames;
    NSString *substring;
    if(![self _canTakeValueFromPasteboard:pb]) {
        return NO;
    }
    filenames = [pb propertyListForType: NSFilenamesPboardType];
    substring = [filenames objectAtIndex: 0];
    if([self _canAccept: substring]) {
        [self setPath: substring];
        [self sendAction: [self action] to:[self target]];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)_canAccept: (NSString *)aPath
{
    NSString *ext = [aPath pathExtension];
    NSString *fileType = NSHFSTypeOfFile(aPath);
    return ([acceptedTypes containsObject: ext] || [acceptedTypes containsObject: fileType]);
}

- (void)setRootForFilePanel: (NSString *)rPath
{
    [rPath retain];
    [rootForFilePanel release];
    rootForFilePanel = rPath;
}

- (NSString *)rootForFilePanel
{
    return rootForFilePanel;
}

- (void)mouseDown:(NSEvent *)event
{
    NSOpenPanel *panel;
    if([event clickCount] != 2) {
        [super mouseDown: event];
    }
    else {
        // I want to begin an open sheet
        panel = [NSOpenPanel openPanel];
        [panel setCanChooseFiles: YES];
        [panel setCanChooseDirectories: NO];
        [panel setAllowsMultipleSelection: NO];

        [panel beginSheetForDirectory: rootForFilePanel
                                 file: nil
                                types: acceptedTypes
                       modalForWindow: [self window]
                        modalDelegate: self
                       didEndSelector: @selector(openPanelDidEnd: returnCode: contextInfo:)
                          contextInfo: nil];
    }
}

- (void)openPanelDidEnd:(NSOpenPanel *)openPanel returnCode:(int)returnCode contextInfo:(void *)x
{
    NSString *sPath;
    if(returnCode == NSOKButton) {
        sPath = [openPanel filename];
        [self setPath: sPath];
        [self sendAction: [self action] to:[self target]];
    }
    //[self setNeedsDisplay: YES];
}

- (void)dealloc
{
    [rootForFilePanel release];
    [acceptedTypes release];
    [super dealloc];
}

- (NSImage*)defaultIcon
{
	NSString* ext = [self requiredExtension];
	if(ext != nil) {
		return [[NSWorkspace sharedWorkspace] iconForFileType: ext];
	} else {
		return [[NSWorkspace sharedWorkspace] iconForFileType: nil];
	}
}

@end
