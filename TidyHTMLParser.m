//
//  TidyHTMLParser.m
//  DreamCatcher
//
//  Created by James Howard on 4/17/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "TidyHTMLParser.h"
#import "DCProperties.h"
#import "Page.h"

@interface TidyHTMLParser (Private)

- (void)stripNodesFromDocument: (NSXMLDocument*)doc
						ofType: (NSString*)tagName;

@end

@implementation TidyHTMLParser

- (BOOL)canHandleType: (NSString*)mimeType
{
	return [mimeType caseInsensitiveCompare: @"text/html"] == NSOrderedSame;
}

- (Response*)parseContent: (NSData*)content
			 fromResponse: (NSURLResponse*)response
			   setAnchors: (NSMutableSet*)anchorSet
{
	NSError* error = nil;
	NSXMLDocument* doc = [[NSXMLDocument alloc] initWithData: content 
													 options: NSXMLDocumentTidyHTML 
													   error: &error];
#ifdef DEBUG
	if(error) {
		NSLog(@"Error resulted whilst parsing %@ : %@", [[response URL] absoluteString], [error description]);
	}
#endif
	if(!doc) {
		return [[[Page alloc] initWithURL: [response URL]
								 pageText: @""] autorelease];
	} 
	if([response textEncodingName] != nil) {
		[doc setCharacterEncoding: [response textEncodingName]];
	} else {
		NSString* defaultEncoding = [[DCProperties defaults] stringForKey: @"DefaultEncoding"];
		if(defaultEncoding == nil) {
			[doc setCharacterEncoding: (NSString*)(CFStringConvertEncodingToIANACharSetName(kCFStringEncodingISOLatin1))];
		}
	}
	
	
	// first walk for anchors
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSArray* anchors = [doc nodesForXPath: @".//a" error: nil];
	NSEnumerator *e = [anchors objectEnumerator];
	NSXMLElement* anchor = nil;
	while((anchor = [e nextObject]) != nil) {
		NSXMLNode* href = [anchor attributeForName: @"href"];
		if(href) {
			NSURL* url = nil;
			@try {
				url = [[NSURL URLWithString: [href stringValue] 
							  relativeToURL: [response URL]] absoluteURL];
			} @catch(id anException) {
				continue;
			}
			if(url != nil) {
				[anchorSet addObject: url];
			}
		}
	}
	[pool release];
	
	// make plain text out of the html
	
	// first strip out all of the tags that contain text but not text we're
	// interested in (script, style, comment, and head tags).
	pool = [[NSAutoreleasePool alloc] init];
	[self stripNodesFromDocument: doc ofType: @"head"];
	[self stripNodesFromDocument: doc ofType: @"script"];
	[self stripNodesFromDocument: doc ofType: @"style"];
	[self stripNodesFromDocument: doc ofType: @"comment()"];
	[pool release];
	
	// now extract all of the text nodes in the document
	pool = [[NSAutoreleasePool alloc] init];
	NSMutableString* result = [[NSMutableString alloc] init];
	NSEnumerator* textNodes = [[doc nodesForXPath: @".//text()" error: nil] objectEnumerator];
	NSXMLNode* textNode = nil;
	while((textNode = [textNodes nextObject]) != nil) {
		[result appendString: [textNode stringValue]];
		[result appendString: @" "];
	}
	Page* ret = [[Page alloc] initWithURL: [response URL]
								 pageText: result];
    [result release];
	[doc release];
	[pool release];
	return [ret autorelease];
}

- (void)stripNodesFromDocument: (NSXMLDocument*)doc
						ofType: (NSString*)tagName
{
	NSEnumerator* tags = [[doc nodesForXPath: [NSString stringWithFormat: @".//%@", tagName] error: nil] objectEnumerator];
	NSXMLNode *tag = nil;
	while((tag = [tags nextObject]) != nil) {
		[tag detach];
	}
}

@end
