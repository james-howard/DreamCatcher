//
//  DSFolderDrag.h
//  DirectSync
//
//  Created by James Howard on Sun Oct 27 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//#import "debug.h"

@interface DSFolderDrag : NSImageView {
    NSString *path;
    NSImage *iconImage;
    NSMutableDictionary *attributes;
    BOOL dragSessionInProgress;
    NSString *rootForFilePanel;
}

- (void)setPath: (NSString *)fpath;
- (NSString *)path;

- (void)prepareAttributes;

- (BOOL)_takeValueFromPasteboard: (NSPasteboard *)pb operationName:(NSString *)op;
- (BOOL)_canTakeValueFromPasteboard: (NSPasteboard *)pb;
- (IBAction)paste:(id)sender;

- (void)openPanelDidEnd:(NSOpenPanel *)openPanel returnCode:(int)returnCode contextInfo:(void *)x;

- (void)setRootForFilePanel: (NSString *)path;
- (NSString *)rootForFilePanel;

- (NSImage*)defaultIcon;


@end
