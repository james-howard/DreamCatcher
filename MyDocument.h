#import <Cocoa/Cocoa.h>
#import "ProgressListener.h"
@class Spider;
@class SpellingError;

typedef enum Status {
	idle,
	spidering,
	spellchecking,
} Status;

@interface MyDocument : NSDocument <ProgressListener>
{
	IBOutlet id docWindow;
	IBOutlet id docView;
	
	NSWindow* lastWindow;
	
#pragma mark urlEntryWindow items
    IBOutlet id urlEntryWindow;
    IBOutlet id beginButton;
    IBOutlet id urlEntryBox;

#pragma mark progressWindow items
    IBOutlet id progressWindow;
    IBOutlet id urlDisplayBox;
    IBOutlet id progressBox;
    IBOutlet id cancelButton;
	IBOutlet id progressSpinner;
    
#pragma mark resultsWindow items
    IBOutlet id resultsWindow;
    IBOutlet id spellingTree;
    IBOutlet id webView;
	IBOutlet id webTabView;
	IBOutlet id loadingPageProgressSpinner;
	IBOutlet id loadingPageLabel;
	
// private
	// set by the webloc loading fn
	NSString* urlToLoad;
	
	Status status;
	
	Spider* spider;
	BOOL cancelled;
	
	NSDictionary* misspellings;
	NSArray* sortedPages;
	SpellingError* highlightError;
	NSURL* currentURL;
	
	BOOL showAllURLS;
	
	NSConditionLock* spellingLock;
	NSAppleScript* scriptHandler;
}

- (IBAction)urlEntryBoxAction: (id)sender;
- (IBAction)beginButtonAction: (id)sender;

- (IBAction)cancelButtonAction: (id)sender;

- (IBAction)spellingTreeAction: (id)sender;

- (IBAction)ignore: (id)sender;
- (IBAction)ignoreAll: (id)sender;
- (IBAction)addWord: (id)sender;
- (IBAction)fixMisspelling: (id)sender;
- (IBAction)toggleShowAllURLS: (id)sender;

- (IBAction)showPreferences: (id)sender;

@end
