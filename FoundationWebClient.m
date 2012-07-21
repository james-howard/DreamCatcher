//
//  FoundationWebClient.m
//  DreamCatcher
//
//  Created by James Howard on 8/7/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "FoundationWebClient.h"
#import <Quartz/Quartz.h>
#import <CoreFoundation/CoreFoundation.h>

#import "ErrorResponse.h"
#import "UnknownTypeResponse.h"
#import "Page.h"
#import "DCProperties.h"
#import "EntityReference.h"
#import "DCUtil.h"
#import "TidyHTMLParser.h"

// a few default content parsers
@interface PlainTextContentParser : NSObject <ContentParser>
- (BOOL)canHandleType: (NSString*)mimeType;

- (Response*)parseContent: (NSData*)content
			 fromResponse: (NSURLResponse*)response
			   setAnchors: (NSMutableSet*)anchorSet;
@end

@interface PDFContentParser : NSObject <ContentParser>
- (BOOL)canHandleType: (NSString*)mimeType;

- (Response*)parseContent: (NSData*)content
			 fromResponse: (NSURLResponse*)response
			   setAnchors: (NSMutableSet*)anchorSet;
@end

@interface RTFContentParser : NSObject <ContentParser>
- (BOOL)canHandleType: (NSString*)mimeType;

- (Response*)parseContent: (NSData*)content
			 fromResponse: (NSURLResponse*)response
			   setAnchors: (NSMutableSet*)anchorSet;
@end

@interface DOCContentParser : NSObject <ContentParser>
- (BOOL)canHandleType: (NSString*)mimeType;

- (Response*)parseContent: (NSData*)content
			 fromResponse: (NSURLResponse*)response
			   setAnchors: (NSMutableSet*)anchorSet;
@end

@interface FoundationWebClient (private)

- (id <ContentParser>)parserForType: (NSString*)mimeType;

@end

@implementation FoundationWebClient

- (id)init
{
	if(self = [super init]) {
		contentParsers = [[NSMutableArray alloc] init];
		[self registerContentParser: [[[PlainTextContentParser alloc] init] autorelease]];
        [self registerContentParser: [[[TidyHTMLParser alloc] init] autorelease]];
        [self registerContentParser: [[[RTFContentParser alloc] init] autorelease]];
		[self registerContentParser: [[[PDFContentParser alloc] init] autorelease]];
        [self registerContentParser: [[[DOCContentParser alloc] init] autorelease]];
	}
	return self;
}

- (void)dealloc
{
    [super dealloc];
    [contentParsers release];
}

- (void)registerContentParser: (id<ContentParser>)parser
{
	[contentParsers addObject: parser];
}

- (id<ContentParser>)parserForType: (NSString*)mimeType;
{
	id<ContentParser> parser = nil;
	NSEnumerator* e = [contentParsers objectEnumerator];
	while((parser = [e nextObject]) != nil) {
		if([parser canHandleType: mimeType]) {
			return parser;
		}
	}
	return nil;
}

- (Response*)fetchAndParsePage: (NSURL*)url
                    setAnchors: (NSMutableSet*)anchorSet
{
	NSURLResponse* response = nil;
	NSError* error = nil;
	NSData* contents = nil;
	NSMutableURLRequest *request = nil;
	
	// start by doing a HEAD request and making sure that the response
	// is going to be a type that I can handle.  I don't want to 
	// go downloading a bunch of stuff that isn't something i can
	// parse and spellcheck
	
	request = [NSMutableURLRequest requestWithURL: url];
    NSString* userAgentString = 
        [[NSString alloc] initWithFormat: @"%@", 
            [[DCProperties defaults] stringForKey: @"User-Agent"]];
	[request setHTTPMethod: @"HEAD"];
    [request setValue: userAgentString forHTTPHeaderField: @"User-Agent"];
	[NSURLConnection sendSynchronousRequest: request 
						  returningResponse: &response
									  error: &error];
	
	if(error != nil) {
		[userAgentString release];
		return [[[ErrorResponse alloc] initWithURL: url 
										 errorCode: [error code]] autorelease];
	}
	
	id<ContentParser> parser = [self parserForType: [response MIMEType]];
	
	if(parser == nil) {
		// can't handle this type
        [userAgentString release];
		return [[[UnknownTypeResponse alloc] 
					initWithURL: url 
						   type: [response MIMEType]] autorelease];
	}
	
	request = [NSMutableURLRequest requestWithURL: url];
    [request setValue: userAgentString forHTTPHeaderField: @"User-Agent"];
	contents = [NSURLConnection sendSynchronousRequest: request
									 returningResponse: &response
												 error: &error];
	
	if(error != nil) {
		return [[[ErrorResponse alloc] initWithURL: url 
										 errorCode: [error code]] autorelease];
	}
	
    [userAgentString release];
    
	return [parser parseContent: contents 
				   fromResponse: response 
					 setAnchors: anchorSet];	
}

@end

@implementation PlainTextContentParser

- (BOOL)canHandleType: (NSString*)mimeType
{
	return [mimeType caseInsensitiveCompare: @"text/plain"] == NSOrderedSame;
}

- (Response*)parseContent: (NSData*)content
			 fromResponse: (NSURLResponse*)response
			   setAnchors: (NSMutableSet*)anchorSet
{
	NSStringEncoding nsEncoding = [DCUtil encodingForResponse: response];
	NSString* contentString = [[NSString alloc] initWithData: content
													encoding: nsEncoding];
	Page* ret = [[Page alloc] initWithURL: [response URL] 
								 pageText: contentString];
	[contentString release];
	return [ret autorelease];
}

@end // PlainTextContentParser

@implementation PDFContentParser

- (BOOL)canHandleType: (NSString*)mimeType
{
	return [mimeType caseInsensitiveCompare: @"application/pdf"] == NSOrderedSame;
}

- (Response*)parseContent: (NSData*)content
			 fromResponse: (NSURLResponse*)response
			   setAnchors: (NSMutableSet*)anchorSet
{
	PDFDocument* pdfDoc = [[PDFDocument alloc] initWithData: content];
	NSString* stringRep = [pdfDoc string];
	Page* ret = [[Page alloc] initWithURL: [response URL]
								 pageText: stringRep];
	[pdfDoc release];
	return [ret autorelease];
}

@end // PDFContentParser

@implementation RTFContentParser

- (BOOL)canHandleType: (NSString*)mimeType
{
	return [mimeType caseInsensitiveCompare: @"text/rtf"] == NSOrderedSame
		|| [mimeType caseInsensitiveCompare: @"text/richtext"] == NSOrderedSame
	|| [mimeType caseInsensitiveCompare: @"application/rtf"] == NSOrderedSame;
}

- (Response*)parseContent: (NSData*)content
			 fromResponse: (NSURLResponse*)response
			   setAnchors: (NSMutableSet*)anchorSet
{
	NSAttributedString* attrString = 
		[[NSAttributedString alloc] initWithRTF: content 
							 documentAttributes: nil];
	if(attrString == nil) {
		return [[[UnknownTypeResponse alloc] initWithURL: [response URL] 
													type: @"malformed rtf"] autorelease];
	}
	
	// return just the plain text
	Page* ret = [[Page alloc] initWithURL: [response URL] 
							 pageText: [attrString string]];
	[attrString release];
	return [ret autorelease];
		
} 

@end // RTFContentParser

@implementation DOCContentParser

- (BOOL)canHandleType: (NSString*)mimeType
{
	return [mimeType caseInsensitiveCompare: @"application/msword"] == NSOrderedSame;
}

- (Response*)parseContent: (NSData*)content
			 fromResponse: (NSURLResponse*)response
			   setAnchors: (NSMutableSet*)anchorSet
{
	NSAttributedString* attrString = 
    [[NSAttributedString alloc] initWithDocFormat: content
                               documentAttributes: nil];
	if(attrString == nil) {
		return [[[UnknownTypeResponse alloc] initWithURL: [response URL] 
													type: @"malformed word doc"] autorelease];
	}
	
	// return just the plain text
	Page* ret = [[Page alloc] initWithURL: [response URL] 
                                 pageText: [attrString string]];
	[attrString release];
	return [ret autorelease];
    
} 

@end // DOCContentParser

