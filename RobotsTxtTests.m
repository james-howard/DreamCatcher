//
//  RobotsTxtTests.m
//  DreamCatcher
//
//  Created by James Howard on 8/11/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "RobotsTxtTests.h"
#import "RobotsTxt.h"

@implementation RobotsTxtTests

- (void)testRobotsTxt
{
    NSString* txt = 
    @"# This is the sample robots text file I'm using for my test.\n"
    @"User-agent: googlebot\n"
    @"Disallow: /no-google/\n"
    @"some random crap\n"
    @"User-agent: *\n"
    @"Disallow: /no-body/\n"
    @"User-agent: dreamcatcher\n"
    @"Disallow: /no-dreamcatcher1/\n"
    @"Disallow: /no-dreamcatcher2/\n"
    @"User-agent: *\n"
    @"Disallow: /gimme-back-my-black-tshirt/\n";
    
    RobotsTxt* robotsTxt = [[RobotsTxt alloc] initWithRootURL: [NSURL URLWithString: @"http://www.host.com"]
                                                 useRobotsTxt: txt];
    
    STAssertTrue([robotsTxt allowURL: [NSURL URLWithString: @"http://www.nothost.com"]],
                 @"Check that urls for other hosts are allowed");
    
    STAssertTrue([robotsTxt allowURL: [NSURL URLWithString: @"http://www.host.com/no-google/index.html"]],
                 @"Check that a blocked url for googlebot, but not for dreamcatcher is allowed");
    
    STAssertFalse([robotsTxt allowURL: [NSURL URLWithString: @"http://www.host.com/no-body/index.html"]],
                  @"Check that a blocked url for all user-agents is blocked");
    
    STAssertFalse([robotsTxt allowURL: [NSURL URLWithString: @"http://www.host.com/no-dreamcatcher1/file.txt"]],
                  @"Check that a blocked url for dreamcatcher is blocked");
    
    STAssertFalse([robotsTxt allowURL: [NSURL URLWithString: @"http://www.host.com/no-dreamcatcher2/rad.txt"]],
                  @"Check that a second blocked url for dreamcatcher is blocked");
    
    STAssertFalse([robotsTxt allowURL: [NSURL URLWithString: @"http://www.host.com/gimme-back-my-black-tshirt/index.html"]],
                  @"Check that a second blocked url for all user-agents is blocked");    
    
}

@end
