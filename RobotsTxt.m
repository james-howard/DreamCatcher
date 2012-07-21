#import "RobotsTxt.h"
#import "DCProperties.h"
#import "DCUtil.h"

@interface RobotsTxt (private)

- (void)parseText: (NSString*)text;

@end

@implementation RobotsTxt

- (id)initWithRootURL: (NSURL*)_rootURL
{
    // fetch the robots.txt
    NSURLResponse* response;
    NSError* error;
    NSData* contents;
    NSMutableURLRequest *request;
    
    NSURL* robotsURL = [[NSURL alloc] initWithScheme: [_rootURL scheme]
                                                host: [_rootURL host]
                                                path: @"/robots.txt"];
    
    request = [NSMutableURLRequest requestWithURL: robotsURL];
    NSString* userAgentString = 
        [[NSString alloc] initWithFormat: @"%@", 
            [[DCProperties defaults] stringForKey: @"User-Agent"]];
    [request setValue: userAgentString forHTTPHeaderField: @"User-Agent"];
    contents = [NSURLConnection sendSynchronousRequest: request 
                                     returningResponse: &response
                                                 error: &error];
    [userAgentString release];
    [robotsURL release];
    
    if(error != nil) {
        // couldn't get robots.txt
        return [self initWithRootURL: _rootURL
                        useRobotsTxt: nil];
    }
    
    NSStringEncoding nsEncoding = [DCUtil encodingForResponse: response];
	NSString* contentString = [[[NSString alloc] initWithData: contents
													encoding: nsEncoding] autorelease];
    
    return [self initWithRootURL: _rootURL
                    useRobotsTxt: contentString];
    
}

- (id)initWithRootURL: (NSURL*)_rootURL
         useRobotsTxt: (NSString*)robotsTxt
{
    if(self = [super init]) {
        // robots.txt is always relative to the root of the server
        rootURL = [[NSURL alloc] initWithScheme: [_rootURL scheme] 
                                           host: [_rootURL host]
                                           path: @"/"];
        blackList = [[NSMutableSet alloc] init];
        if(robotsTxt != nil) {
            [self parseText: robotsTxt];
        }
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
 
    [rootURL release];
    [blackList release];
}

- (void)parseText: (NSString*)robotsTxt
{
    // For info on robots.txt format, see 
    // http://www.w3.org/TR/REC-html40/appendix/notes.html#h-B.4.1.1
    
    NSRegularExpression* userAgent = [NSRegularExpression regularExpressionWithPattern:@"User-agent:\\s*(.*)" options: NSRegularExpressionCaseInsensitive error:NULL];
    
    NSRegularExpression* disallow = [NSRegularExpression regularExpressionWithPattern:@"Disallow:\\s*(.*)"
                                                                          options:NSRegularExpressionCaseInsensitive 
                                                                            error:NULL];
    
    NSArray* lines = [robotsTxt componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    BOOL adding = NO;
    NSEnumerator* e = [lines objectEnumerator];
    NSString* line = nil;
    while((line = [e nextObject]) != nil) {
        line = [line stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSUInteger commentIndex = [line rangeOfString: @"#"].location;
        if(commentIndex != NSNotFound) {
            line = [line substringToIndex: commentIndex];
        }
        NSTextCheckingResult* match = [userAgent firstMatchInString:line options:0 range:NSMakeRange(0, [line length])];
        if (match != nil) {
            // ok, found a user agent
            NSString *agentName = [line substringWithRange:[match rangeAtIndex:1]];
            if(agentName != nil) {
                if([agentName rangeOfString: @"*"].location != NSNotFound
                   || [[agentName lowercaseString] rangeOfString: @"dreamcatcher"].location != NSNotFound) 
                {
                    adding = YES;
                } else {
                    adding = NO;
                }
            }
            continue;
        }
        // not a user agent, check for a disallow line
        if(adding) {
            match = [disallow firstMatchInString:line options:0 range:NSMakeRange(0, [line length])];
            if(match != nil) {
                NSString* disallowText = [line substringWithRange:[match rangeAtIndex:1]];
                if(disallowText != nil) {
                    disallowText = [disallowText stringByTrimmingCharactersInSet: 
                        [NSCharacterSet whitespaceCharacterSet]];
                    [blackList addObject: disallowText];
                }
            }
        }
    }
    
}

- (BOOL)allowURL: (NSURL*)url
{
    // first, the url needs to be at least on the same host as the robots.txt
    // applies to.  if you're interested in transferring to another host
    // you can go make your own RobotsTxt object for that host.
    if([[rootURL host] isEqualToString: [url host]]) {
        NSEnumerator* e = [blackList objectEnumerator];
        NSString* blackURL = nil;
        while((blackURL = [e nextObject]) != nil) {
            if([[url path] rangeOfString: blackURL].location != NSNotFound) {
                return NO;
            }
        }
    } 
    return YES;
}


@end
