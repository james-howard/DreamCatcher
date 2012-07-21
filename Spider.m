#import "Spider.h"

#import "ConditionVariable.h"
#import "Response.h"
#import "Page.h"
#import "FoundationWebClient.h"
#import "RobotsTxt.h"
#import "DCProperties.h"

#import <libkern/OSAtomic.h>
#import <pthread.h>

static id<WebClient> sharedWebClient = nil;

// URLPkg is a little private helper class so I don't spider too deep.
@interface URLPkg : NSObject
{
    NSURL* url;
    int depth;
}

- (id)initWithURL: (NSURL*)_url
            depth: (int)_depth;
- (NSURL*)url;
- (int)depth;

@end

@implementation URLPkg 

- (id)initWithURL: (NSURL*)_url
            depth: (int)_depth
{
    if(self = [super init]) {
        url = [_url retain];
        depth = _depth;
    }
    return self;
}
- (void)dealloc
{
	[url release];
    [super dealloc];
}
- (NSURL*)url
{
    return url;
}
- (int)depth
{
    return depth;
}
@end // URLPkg


@interface Spider (private)

- (void)setupRun;
- (void)spawnWorkers;
- (void)workerLoop;
- (void)watchWorkers;
- (void)cleanup;
- (void)spiderURL: (URLPkg*)url;
- (void)addNewURLs: (NSSet*)newURLs
             depth: (int)depth;
- (NSURL*)normalizeURL: (NSURL*)url;
- (BOOL)shouldKeepURL: (NSURL*)url;

- (void)notifyListenersWithURL: (NSURL*)url;

+ (id<WebClient>)webClient;

@end

@implementation Spider

+ (id<WebClient>)webClient
{
    if(sharedWebClient == nil) {
        sharedWebClient = [[FoundationWebClient alloc] init];
    }
    return sharedWebClient;
}

- (id)initWithBaseURL: (NSURL*)_base
	   maxSearchDepth: (int)_depth
{
	if(self = [super init]) {
		baseUrl = [_base retain];
		maxSearchDepth = _depth;
        pageDict = nil;
        obeyRobotsTxt = YES;
        robotsTxts = [[NSMutableDictionary alloc] init];
        listeners = [[NSMutableSet alloc] init];

		numWorkers = [[DCProperties defaults] integerForKey: @"SpiderThreads"];
		done = YES;
		spiderQueue = nil;
		spiderCond = nil;
		spiderQueueMutex = nil;
		pageDictMutex = nil;
	}
    return self;
}

- (void)dealloc
{
	done = YES;
	
	[baseUrl release];
    [listeners release];
	baseUrl = nil;
	[self cleanup];

	[super dealloc];
}

- (BOOL)isDone
{
	return done;
}

- (void)cancel
{
	done = YES;
	[spiderCond cancelBlockingOnNumberOfWaiters];
}

- (int)pagesSpidered
{
	return pagesSpidered;
}
- (void)setPagesSpidered: (int)_val
{
	pagesSpidered = _val;
}

- (void)cleanup
{
	if(spiderQueue != nil) {
		[spiderQueue release];
        spiderQueue = nil;
	}
	if(spiderQueueMutex != nil) {
		[spiderQueueMutex release];
        spiderQueueMutex = nil;
	}
	if(pageDictMutex != nil) {
		[pageDictMutex release];
        pageDictMutex = nil;
	}
	if(spiderCond != nil) {
		[spiderCond release];
        spiderCond = nil;
	}
    if(pageDict != nil) {
        [pageDict release];
        pageDict = nil;
    }
    if(robotsTxts != nil) {
        [robotsTxts release];
        robotsTxts = nil;
    }
    assert(workersWorking == 0);
}

- (void)setupRun
{
    [self cleanup];
    URLPkg* startPkg = [[URLPkg alloc] initWithURL: baseUrl
                                             depth: 0];
    spiderQueue = [[NSMutableSet alloc] initWithObjects: startPkg, nil];
    [startPkg release];
    spiderCond = [[ConditionVariable alloc] init];
    spiderQueueMutex = [[NSLock alloc] init];
    pageDictMutex = [[NSLock alloc] init];
	pageDict = [[NSMutableDictionary alloc] init];
    robotsTxts = [[NSMutableDictionary alloc] init];
	workersWorking = 0;
}

- (void)spawnWorkers
{
    for(int i = 0; i < numWorkers; i++) {
        [NSThread detachNewThreadSelector: @selector(workerLoop) 
                                 toTarget: self 
                               withObject: nil];
    }
}

- (void)workerLoop
{
    [self retain];
    OSAtomicIncrement32Barrier(&workersWorking);
    while(!done) {
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
        [spiderQueueMutex lock];
        URLPkg* url = [[[spiderQueue objectEnumerator] nextObject] retain];
        if(url != nil) {
            [spiderQueue removeObject: url];
        }
        [spiderQueueMutex unlock];
        if(url == nil) {
            [spiderCond wait];
			[pool release];
            continue;
        }
        [self spiderURL: url];
		[url release];
	    [pool release];
    }
	OSAtomicDecrement32Barrier(&workersWorking);
    [self release];
	//NSLog(@"worker exits");
}

- (void)watchWorkers
{
    [spiderCond blockUntilNumberOfWaiters: numWorkers];
	[spiderCond signalAll];
    done = YES;
}

- (void)blockingRun
{
    done = NO;
    [self setupRun];
    [self spawnWorkers];
    [self watchWorkers];
}

- (void)spiderURL: (URLPkg*)url
{
    if([url depth] > maxSearchDepth) return;
	NSURL* normalURL = [self normalizeURL: [url url]];
    [pageDictMutex lock];
    if([pageDict objectForKey: normalURL] != nil) {
        // then the page is already spidered
		[pageDictMutex unlock];
        return;
    } else {
		// add the page temporarily to the set, so it won't be spidered
		// again while its being fetched
		[pageDict setObject: @"in progress" forKey: normalURL];
	}
    [pageDictMutex unlock];
    NSMutableSet* anchorSet = [[NSMutableSet alloc] init];
	//NSLog(@"Spider.spiderURL: fetching url: %@", normalURL);
    [self notifyListenersWithURL: normalURL];
    Response* r = [[Spider webClient] fetchAndParsePage: normalURL
                                             setAnchors: anchorSet];
    [r retain];
    [pageDictMutex lock];
    [pageDict setObject: r 
				 forKey: normalURL];
    [pageDictMutex unlock];
    [r release];
    [self addNewURLs: anchorSet
               depth: ([url depth] + 1)];
    [anchorSet release];
}

- (void)addNewURLs: (NSSet*)newURLs
             depth: (int)depth
{
    [spiderQueueMutex lock];
    [pageDictMutex lock];
    NSEnumerator* e = [newURLs objectEnumerator];
    NSURL* url = nil;
    while(url = [e nextObject]) {
        NSURL* normalURL = [self normalizeURL: url];
        if([pageDict objectForKey: normalURL] == nil) {
			if([self shouldKeepURL: url]) {
				URLPkg *pkg = [[URLPkg alloc] initWithURL: normalURL depth: depth];
				[spiderQueue addObject: pkg];
				[pkg release];
				[spiderCond signal];
			}
        }
    }
    [pageDictMutex unlock];
    [spiderQueueMutex unlock];
}

- (NSURL*)normalizeURL: (NSURL*)url
{
    // remove #anchor type references.  i don't care about those
    // because i just want to look at the whole page text
	// XXX: this is lame
	NSString* urlstr = [[url standardizedURL] absoluteString];
	NSString* revised = urlstr;
	for(int i = [urlstr length] - 1; i >= 0; i--) {
		if([urlstr characterAtIndex: i] == '#') {
			revised = [urlstr substringToIndex: i];
			break;
		}
	}
	@try {
		return [NSURL URLWithString: revised];
	} @catch(id anException) {
		return nil;
	}
	return nil;
}

- (BOOL)shouldKeepURL: (NSURL*)url
{
	if([self normalizeURL: url] == nil) {
		return NO;
	}
	// only want to keep urls that are on the same site as
	// base url and that aren't disallowed by robots.txt
	if([[url host] isEqualToString: [baseUrl host]]) {
        if(obeyRobotsTxt) {
            // check and see if there is a robotsTxt for this site
            // (yes, i'm aware of the contradiction of keeping it on
            // one site, but having a design that allows for multiple
            // robots.txts, one for each host)
            RobotsTxt* robotsTxt = [robotsTxts objectForKey: [url host]];
            if(robotsTxt == nil) {
                robotsTxt = [[RobotsTxt alloc] initWithRootURL: 
                    [[[NSURL alloc] initWithScheme: [url scheme] 
                                              host: [url host] 
                                              path: @"/"] autorelease]];
                [robotsTxts setObject: robotsTxt forKey: [url host]];
				[robotsTxt release];
            }
            return [robotsTxt allowURL: url];
        } else {
            return YES;
        }
    }
	// added to support file:// type urls
    return ([baseUrl host] == nil && [url host] == nil);
}

- (BOOL)obeysRobotsTxts
{
    return obeyRobotsTxt;
}
- (void)setObeysRobotsTxts: (BOOL)flag
{
    obeyRobotsTxt = flag;
}

- (Page*)pageForURL: (NSURL*)url
{
    return [pageDict objectForKey: url];
}

- (NSEnumerator*)urls
{
    NSMutableArray* pageArray = [[NSMutableArray alloc] init];
	NSEnumerator* e = [pageDict keyEnumerator];
	NSURL* key = nil;
	while((key = [e nextObject]) != nil) {
		id value = [pageDict objectForKey: key];
		if([value isKindOfClass: [Page class]]) {
			[pageArray addObject: key];
		}
	}
	[pageArray autorelease];
	return [pageArray objectEnumerator];
}

- (void)notifyListenersWithURL: (NSURL*)url
{
    NSEnumerator* e = [listeners objectEnumerator];
    id<ProgressListener> listener;
    while((listener = [e nextObject]) != nil) {
        [listener fetchingURL: url
                   fromSpider: self];
    }
}

- (void)addProgressListener: (id <ProgressListener>)listener
{
    [listeners addObject: listener];
}

- (void)removeProgressListener: (id <ProgressListener>)listener
{
    [listeners removeObject: listener];
}

@end
