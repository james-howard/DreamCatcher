//
//  SpiderTests.m
//  DreamCatcher
//
//  Created by James Howard on 7/4/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "SpiderTests.h"
#import "DCProperties.h"
#import "Spider.h"
#import "Page.h"

@implementation SpiderTests

- (void)testSpider
{
    // test answers
    NSString* testRoot = 
    [[[DCProperties defaults] stringForKey: @"test_url"] stringByAppendingString: @"spider/index.html"];
    int pagesInTest = 7;
    
    NSString* leaf1Url =  
        [[[DCProperties defaults] stringForKey: @"test_url"] stringByAppendingString: @"spider/leaf1-1.html"];
    NSString* leaf1Content = @"Leaf 1-1";
    
    
    
	Spider* spider = [[Spider alloc] initWithBaseURL: [NSURL URLWithString: testRoot]
									  maxSearchDepth: 10];
	
	[spider blockingRun];
	
	NSEnumerator* urlsEnumerator = [spider urls];
	NSURL *url = nil;
	int count = 0;
	while(url = [urlsEnumerator nextObject]) {
		STAssertNotNil([spider pageForURL: url], @"enumerated urls ought to correspond to existing pages");
		count++;
	}
	
	STAssertEquals(count, pagesInTest, @"pages in test");
	
	// check the content of a few pages
	Page* p = [spider pageForURL: [NSURL URLWithString: leaf1Url]];
	NSString* content = [p text];
	STAssertNotNil(content, @"content should not be nil");
	content = [content stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	STAssertEqualObjects(content, leaf1Content, @"leaf 1 content test");
	
	[spider release];
}

@end

