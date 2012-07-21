#import <Cocoa/Cocoa.h>
#import <SenTestingKit/SenTestingKit.h>

int main(int argc, char** argv)
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    SenTestSuite* suite = [SenTestSuite defaultTestSuite];
    SenTestRun* run = [suite run];
    int ret = [run failureCount];
    [pool release];
    return ret;
}
