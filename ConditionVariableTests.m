//
//  ConditionVariableTests.m
//  DreamCatcher
//
//  Created by James Howard on 7/7/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "ConditionVariableTests.h"
#import "ConditionVariable.h"

@implementation ConditionVariableTests


- (void)testCond
{
    cond = [[ConditionVariable alloc] init];
    // kick off a few workers
    int numWorkers = 3;
    for(int i = 0; i < numWorkers; i++) { 
        [NSThread detachNewThreadSelector: @selector(workerLoop) 
                                 toTarget: self 
                               withObject: nil];
    }
    [cond blockUntilNumberOfWaiters: numWorkers];

    STAssertEquals(numWorkers, ([cond waiters]), @"Number of Waiters Test");
    
    [cond signalAll];
    // sleep a little to allow the worker threads to wake up and exit
    [NSThread sleepUntilDate: [NSDate dateWithTimeIntervalSinceNow: 1]];
    STAssertEquals(0, ([cond waiters]), @"Number of Waiters Test 2");
}

- (void)workerLoop
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    // wait for a bit, to make sure that the main thread
    // has a chance to block for a bit
    [NSThread sleepUntilDate: [NSDate dateWithTimeIntervalSinceNow: 1]];
    [cond wait];
    STAssertTrue(YES, @"worker finished");
    [pool release];
}

@end
