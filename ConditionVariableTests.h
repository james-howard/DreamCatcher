//
//  ConditionVariableTests.h
//  DreamCatcher
//
//  Created by James Howard on 7/7/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
@class ConditionVariable;

@interface ConditionVariableTests : SenTestCase {
    ConditionVariable* cond;
}

- (void)testCond;

- (void)workerLoop;

@end
