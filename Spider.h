#import <Cocoa/Cocoa.h>
#import "WebClient.h"
#import "ProgressListener.h"
@class ConditionVariable;
@class Page;

@interface Spider : NSObject {

	// NSURLs key to Pages
	NSMutableDictionary* pageDict;
	NSURL* baseUrl;
	
	int maxSearchDepth;
	int pagesSpidered;
    
    BOOL obeyRobotsTxt;
	
	// ----------------------------------------
	// implementation details
	
    NSMutableDictionary* robotsTxts;
    NSMutableSet* listeners;
    
    id <WebClient> webClient;
    
    int numWorkers;
    
	// set of pages that have been discovered but have not yet
	// been selected for spidering
	NSMutableSet* spiderQueue;
	BOOL done;
	
    ConditionVariable* spiderCond;
	
	// protects access to the data structures
	NSLock* spiderQueueMutex;
	NSLock* pageDictMutex;	
	
	int workersWorking;
}

// constructors
- (id)initWithBaseURL: (NSURL*)_base
	   maxSearchDepth: (int)_depth;

// runners
- (void)blockingRun;

// this is safe to call from any thread
- (BOOL)isDone;
// as is this
- (void)cancel;

- (int)pagesSpidered;
- (void)setPagesSpidered: (int)_val;

// these should only be called once spidering is complete
- (NSEnumerator *)urls;
- (Page *)pageForURL: (NSURL *)url;

- (BOOL)obeysRobotsTxts;
- (void)setObeysRobotsTxts: (BOOL)flag;

- (void)addProgressListener: (id <ProgressListener>)listener;
- (void)removeProgressListener: (id <ProgressListener>)listener;

@end
