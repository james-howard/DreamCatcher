#import "ConditionVariable.h"

#import <libkern/OSAtomic.h>
#import <pthread.h>

#define INSUFFICIENT_WAITERS 0
#define SUFFICIENT_WAITERS 1

@interface ConditionVariable (private)

- (void)checkMonitor;

@end

@implementation ConditionVariable

- (id)init
{
    if(self = [super init]) {
        pthread_mutex_init(&mutex, NULL);
        pthread_cond_init(&cond, NULL);
        numWaiters = 0;
        pthread_mutex_init(&waitersMutex, NULL);
        pthread_cond_init(&waitersCond, NULL);
        waitingFor = -1;
    }
    return self;
}
- (void)dealloc
{
    [super dealloc];
    pthread_mutex_destroy(&mutex);
    pthread_cond_destroy(&cond);
    pthread_mutex_destroy(&waitersMutex);
    pthread_cond_destroy(&waitersCond);
}

- (void)wait
{
    OSAtomicIncrement32Barrier(&numWaiters);
    //NSLog(@"ConditionVariable increments numWaiters");
    [self checkMonitor];
    pthread_cond_wait(&cond, &mutex);
    pthread_mutex_unlock(&mutex);
    OSAtomicDecrement32Barrier(&numWaiters);
    //NSLog(@"ConditionVariable decrements numWaiters");
    [self checkMonitor];
}
- (void)waitUntil: (NSDate*)futureDate
{
    struct timespec t;
    double secs = [futureDate timeIntervalSince1970];
    t.tv_sec = trunc(secs);
    t.tv_nsec = (secs - t.tv_sec) * 1.0e10;
    OSAtomicIncrement32Barrier(&numWaiters);
    [self checkMonitor];
    pthread_cond_timedwait(&cond, &mutex, &t);
    OSAtomicDecrement32Barrier(&numWaiters);
    [self checkMonitor];
}

- (void)signal
{
    pthread_cond_signal(&cond);
}
- (void)signalAll
{
    //NSLog(@"ConditionVariable.signalAll: broadcasting to %d waiters", numWaiters);
    pthread_cond_broadcast(&cond);
}

- (int)waiters
{
    return numWaiters;
}

- (void)blockUntilNumberOfWaiters: (int)waiters
{
    while(numWaiters < waiters) {
        waitingFor = waiters;
        pthread_cond_wait(&waitersCond, &waitersMutex);
        pthread_mutex_unlock(&waitersMutex);
    }
    //NSLog(@"ConditionVariable.blockUntilNumberOfWaiters returns");
}

- (void)checkMonitor
{
    if(waitingFor == -1) return;
    if(numWaiters >= waitingFor) {
        //NSLog(@"ConditionVariable.checkMonitor numWaiters satisfied so broadcasting");
        pthread_cond_broadcast(&waitersCond);
        waitingFor = -1;
    }
}

- (void)cancelBlockingOnNumberOfWaiters
{
	numWaiters = waitingFor;
	[self checkMonitor];
}

@end
