//
//  DSFileTypeDrag.h
//  DirectSync
//
//  Created by James Howard on Sun Jan 26 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DSFolderDrag.h"


@interface DSFileTypeDrag : DSFolderDrag {
    NSArray *acceptedTypes;
}

/** These two methods are kept around for compatibility with code that still uses the original version of DSFileTypeDrag
    that only supported a single file extension.  setRequiredExtension will make the acceptedTypes array be set to hold
    simply that file extension and nothing else.  requiredExtension returns the first item in the array
*/
- (void)setRequiredExtension: (NSString *)ext;
- (NSString *)requiredExtension;

/* The types is an NSArray of the same format as the one supplied to NSOpenPanel */
- (void)setAcceptedTypes: (NSArray *)types;
- (NSArray *)acceptedTypes;

- (BOOL)_canAccept: (NSString *)aPath;

@end
