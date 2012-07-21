//
//  ContentParsersTests.m
//  DreamCatcher
//
//  Created by James Howard on 8/11/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "ContentParsersTests.h"

#import "DCProperties.h"
#import "Spider.h"
#import "Page.h"
#import "UnknownTypeResponse.h"
#import "ErrorResponse.h"

@implementation ContentParsersTests

- (void)testContentParsers
{
    NSURL* testRoot = 
                    [[NSURL alloc] initWithString: 
                        [[[DCProperties defaults] stringForKey: @"test_url"]
                            stringByAppendingString: @"ContentParsers/"]];
    
    
    Spider* spider = [[Spider alloc] initWithBaseURL: [NSURL URLWithString: @"content.html" 
                                                             relativeToURL: testRoot]
                                       maxSearchDepth: 3];
    
    [spider blockingRun];
    
    // check each page, and look for the string "Missspelling" to make sure
    // that the page has been parsed (not a perfect test, but its a start)
    
    id page = [spider pageForURL: [NSURL URLWithString: @"content.doc"
                                            relativeToURL: testRoot]];
    STAssertNotNil(page, @"doc was seen");
    if([page isKindOfClass: [Page class]]) {
        STAssertTrue([[page text] rangeOfString: @"Missspelling"].location >= 0, 
                 @"doc contains string: \"Missspelling\"");
    } else if([page isKindOfClass: [UnknownTypeResponse class]]) {
        STFail([NSString stringWithFormat: @"doc was seen as type: %@", [page MIMEType]]);
    } else if([page isKindOfClass: [ErrorResponse class]]) {
        STFail([NSString stringWithFormat: @"doc was returned as error code: %@", [page errorCode]]);
    } else {
        STFail([NSString stringWithFormat: @"doc was returned as unknown type: %@", page]);
    }
    
    page = [spider pageForURL: [NSURL URLWithString: @"content.rtf"
                                            relativeToURL: testRoot]];
    STAssertNotNil(page, @"rtf was seen");
    if([page isKindOfClass: [Page class]]) {
        STAssertTrue([[page text] rangeOfString: @"Missspelling"].location >= 0, 
                     @"rtf contains string: \"Missspelling\"");
    } else if([page isKindOfClass: [UnknownTypeResponse class]]) {
        STFail([NSString stringWithFormat: @"rtf was seen as type: %@", [page MIMEType]]);
    } else if([page isKindOfClass: [ErrorResponse class]]) {
        STFail([NSString stringWithFormat: @"rtf was returned as error code: %@", [page errorCode]]);
    } else {
        STFail([NSString stringWithFormat: @"rtf was returned as unknown type: %@", page]);
    }
    
    page = [spider pageForURL: [NSURL URLWithString: @"content.pdf"
                                            relativeToURL: testRoot]];
    STAssertNotNil(page, @"pdf was seen");
    if([page isKindOfClass: [Page class]]) {
        STAssertTrue([[page text] rangeOfString: @"Missspelling"].location >= 0, 
                     @"pdf contains string: \"Missspelling\"");
    } else if([page isKindOfClass: [UnknownTypeResponse class]]) {
        STFail([NSString stringWithFormat: @"pdf was seen as type: %@", [page MIMEType]]);
    } else if([page isKindOfClass: [ErrorResponse class]]) {
        STFail([NSString stringWithFormat: @"pdf was returned as error code: %@", [page errorCode]]);
    } else {
        STFail([NSString stringWithFormat: @"pdf was returned as unknown type: %@", page]);
    }
    
    page = [spider pageForURL: [NSURL URLWithString: @"content.html"
                                            relativeToURL: testRoot]];
    STAssertNotNil(page, @"html was seen");
    if([page isKindOfClass: [Page class]]) {
        STAssertTrue([[page text] rangeOfString: @"Missspelling"].location >= 0, 
                     @"html contains string: \"Missspelling\"");
    } else if([page isKindOfClass: [UnknownTypeResponse class]]) {
        STFail([NSString stringWithFormat: @"html was seen as type: %@", [page MIMEType]]);
    } else if([page isKindOfClass: [ErrorResponse class]]) {
        STFail([NSString stringWithFormat: @"html was returned as error code: %@", [page errorCode]]);
    } else {
        STFail([NSString stringWithFormat: @"html was returned as unknown type: %@", page]);
    }
    
    
    
    [testRoot release];
    [spider release];
}

@end
