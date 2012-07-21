#import <Cocoa/Cocoa.h>
#import <pthread.h>

@interface ConditionVariable : NSObject {
    pthread_mutex_t mutex;
    pthread_cond_t cond;
    int numWaiters;
    pthread_cond_t waitersCond;
    pthread_mutex_t waitersMutex;
    int waitingFor;
}

- (id)init;

- (void)wait;
- (void)waitUntil: (NSDate*)futureDate;

- (void)signal;
- (void)signalAll;

- (int)waiters;

// this isn't part of the standard condition variable bit, but
// i threw this in here because i found this useful for figuring out
// when an operation with worker threads has concluded by a monitor thread.
// The idea is that the monitor thread blocks until all worker threads
// are waiters.  Then, it sets a flag and signals all the waiters.  The
// waiters wake up and notice the flag, and then they all exit.  Handy, eh?
// The catch is that this only supports a single thread blocking on the
// waiters.  If you call this twice, the outcome is undefined (and by
// undefined I mean bad stuff will happen).    
// Also note that you can use Cocoa's kvo on the waiters method above to implement
// an asynchronous version of this.  You just set kvo up to notify you when
// waiters = number of workers.
- (void)blockUntilNumberOfWaiters: (int)waiters;

- (void)cancelBlockingOnNumberOfWaiters;

@end
