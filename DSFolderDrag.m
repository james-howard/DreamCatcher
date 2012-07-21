//
//  DSFolderDrag.m
//  DirectSync
//
//  Created by James Howard on Sun Oct 27 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "DSFolderDrag.h"


@implementation DSFolderDrag

- (id)initWithFrame: (NSRect)rect
{
    NSArray *pboardtypes;
    if(self = [super initWithFrame: rect]) {
		iconImage = nil;
        [self setPath: nil];
        dragSessionInProgress = NO;
        [self prepareAttributes];
        // give it that sick sunken look :D
        [self setImageFrameStyle: NSImageFrameGrayBezel];
        // load the empty state image
        [self setImage: [self defaultIcon]];
        [self setEditable: YES];
        // I don't want the default drag types.  I want files!
        [self unregisterDraggedTypes];
        pboardtypes = [NSArray arrayWithObjects: NSFilenamesPboardType, nil];
        [self registerForDraggedTypes: pboardtypes];
        [self setRootForFilePanel: @"/"];
    }
    return self;
}

- (void)prepareAttributes
{
    attributes = [[NSMutableDictionary alloc] init];
    [attributes setObject: [NSFont fontWithName:@"Lucida Grande" size: 9] forKey: NSFontAttributeName];
    [attributes setObject: [NSColor blackColor] forKey: NSForegroundColorAttributeName];
}

- (void)drawRect:(NSRect)rect
{
    NSBezierPath *outlinePath;
    NSString *substring, *displayString;
    NSPoint stringOrigin;
    NSSize stringSize, imageSize;
    int supposedLength;
    NSRect bounds = [self bounds];

    // draw the folder image in
    if(iconImage != nil) {
        [self setImageAlignment: NSImageAlignTop];
        [self setImageScaling: NSScaleNone];
        imageSize = NSMakeSize(rect.size.height - 20, rect.size.height - 20);
        [iconImage setSize: imageSize];
        [self setImage: iconImage];
    } else {
		[self setImageAlignment: NSImageAlignCenter];
		[self setImageScaling: NSScaleProportionally];
	}
    [super drawRect:rect];
    // draw the path string in
	if(path != nil) {
		displayString = [path lastPathComponent];
	} else {
		displayString = @"";
	}
    stringSize = [displayString sizeWithAttributes: attributes];
    if(stringSize.width > (rect.size.width - 6)) {
        // then we need to trim it
        supposedLength = ([displayString length] / stringSize.width)*(rect.size.width - 6);
        substring = [displayString substringToIndex: (supposedLength - 3)];
        displayString = [substring stringByAppendingString: @"..."];
        stringSize = [displayString sizeWithAttributes: attributes];
    }
    stringOrigin.x = rect.origin.x + (rect.size.width - stringSize.width) / 2;
    stringOrigin.y = rect.origin.y + stringSize.height/4;
    [displayString drawAtPoint: stringOrigin withAttributes: attributes];
    
    // highlight if first responder
    if (([[self window] firstResponder] == self) || dragSessionInProgress) {
        [[NSColor selectedControlColor] set];
        outlinePath = [[NSBezierPath bezierPathWithRect: bounds] retain];
        [outlinePath setLineWidth: 3];
        [outlinePath setLineJoinStyle: NSRoundLineJoinStyle];
        [outlinePath stroke];
        [outlinePath release];
    }
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pboard = [sender draggingPasteboard];
    unsigned int mask = [sender draggingSourceOperationMask];
    unsigned int ret = (NSDragOperationLink & mask);

    if ([[pboard types] indexOfObject: NSFilenamesPboardType] == NSNotFound) {
        ret = NSDragOperationNone;
    }
    if(ret != NSDragOperationNone) {
        dragSessionInProgress = YES;
        [self setNeedsDisplay: YES];
    }
    return ret;
}
- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    dragSessionInProgress = NO;
    [self setNeedsDisplay: YES];
}
- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
    dragSessionInProgress = NO;
    [self setNeedsDisplay: YES];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    //NSLog(@"DSFolderDrag: prepareForDragOperation");
    return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pb = [sender draggingPasteboard];
    return [self _takeValueFromPasteboard: pb operationName: @"drop"];
}

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)flag
{
    return NSDragOperationLink;
}

- (BOOL)_canTakeValueFromPasteboard: (NSPasteboard *)pb
{
    NSArray *typeArray = [NSArray arrayWithObjects:NSFilenamesPboardType, nil];
    NSString *type = [pb availableTypeFromArray: typeArray];
    if (!type) {
        return NO; 
    }
    return YES;
}

- (BOOL)_takeValueFromPasteboard: (NSPasteboard *)pb operationName:(NSString *)op
{
    NSArray *filenames;
    NSString *substring;
    if(![self _canTakeValueFromPasteboard:pb]) {
#ifdef DEBUG
        NSLog(@"DSFolderDrag: _takeValueFromPasteboard: unable to perform %@ operation", op);
#endif
        return NO;
    }
    filenames = [pb propertyListForType: NSFilenamesPboardType];
    substring = [filenames objectAtIndex: 0];
    [self setPath: substring];
    [self sendAction: [self action] to:[self target]];
    return YES;
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    if ([menuItem action] == @selector(paste:)) {
        NSPasteboard *pb = [NSPasteboard pasteboardWithName: NSGeneralPboard];
        return [self _canTakeValueFromPasteboard:pb];
    }
    return YES;
}

- (IBAction)paste:(id)sender
{
    NSPasteboard *pb = [NSPasteboard pasteboardWithName: NSGeneralPboard];
    [self _takeValueFromPasteboard: pb operationName: @"paste"];
}

- (void)setPath: (NSString *)fpath
{
    // in the future I may want to check the validity of the path.  For now, I don't.
    [fpath retain];
    [path release];
    path = fpath;
    if([path isEqual: @" "]) {
        [self setPath: nil];
		return;
    }
    [self setToolTip: path];
    [iconImage release];
    if(path != nil) {
		iconImage = [[NSWorkspace sharedWorkspace] iconForFile: path];
	} else {
		iconImage = nil;
		[self setImage: [self defaultIcon]];
		return;
	}
    [iconImage retain];
    [iconImage setSize:NSMakeSize(128.0,128.0)];
    [self setNeedsDisplay: YES];
    //[self drawRect: [self frame]];
}
- (NSString *)path
{
    return path;
}

- (NSImage*)defaultIcon {
	return [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForImageResource:@"dsfolderdrag.tiff"]] autorelease];
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
        [panel setCanChooseDirectories: YES];
        [panel setAllowsMultipleSelection: NO];
        
        [panel beginSheetForDirectory: rootForFilePanel
            file: nil
            types: nil
            modalForWindow: [self window]
            modalDelegate: self
            didEndSelector: @selector(openPanelDidEnd: returnCode: contextInfo:)
            contextInfo: nil];
    }
}

- (void)keyDown: (NSEvent*)theEvent
{
	if([theEvent keyCode] == 117 /* delete */ || [theEvent keyCode] == 51 /* backspace */) {
		[self setPath: nil];
	}
}

- (void)openPanelDidEnd:(NSOpenPanel *)openPanel returnCode:(int)returnCode contextInfo:(void *)x
{
    if(returnCode == NSOKButton) {
        [self setPath: [openPanel filename]];
        [self sendAction: [self action] to:[self target]];
    }
    [self setNeedsDisplay: YES];
}


- (void)dealloc
{
    [path release];
    [iconImage release];
	[super dealloc];
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
@end
