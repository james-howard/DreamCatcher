#import <WebKit/WebKit.h>

#import "MyDocument.h"
#import "Spider.h"
#import "Spellchecker.h"
#import "Page.h"
#import "DCProperties.h"
#import "PreferencesController.h"
#import "NSAppleScript+HandlerCalls.h"

#define kErrorHandler (@"error_found")

// this isn't really where this should go, but I'm too lazy to make an application's delegate
// or whatever to hold just this one thing ...
static PreferencesController* preferences = nil;

void alertBox(const char *title, const char *msg) {
	NSRunAlertPanel([NSString stringWithCString: title], [NSString stringWithCString: msg],
					@"OK", nil, nil);
}

@interface MyDocument (private)

- (void)watchSpider;
- (void)spiderFinished;
- (void)addProgress: (NSString*)progressItem;
- (void)populateSpelling;

- (void)changeView: (NSWindow*)window atSpeed: (double)duration;
- (void)selectError: (SpellingError*)error;

- (void)webViewLoaded: (NSNotification*)userInfo;
- (void)doHighlightError;

- (NSData*)exportToHTML;

- (BOOL)pageIsIgnored: (int)indexOfPage;
- (BOOL)pageIsIgnoredByURL: (NSURL*)page;
- (int)countMisspellingsForURL: (NSURL*)url;
- (SpellingError*)currentlySelectedError;
- (void)unignore: (SpellingError*)error;
- (void)unignoreAll: (NSString*)misspelling;
- (void)unAddWord: (NSString*)word;
- (NSString*)ignoreAllImpl;

- (void)buildSpellingContextualMenu;

- (void)spellcheckWorker;
- (void)spellcheckFinished;

- (void)defaultsChanged: (NSNotification*)note;
- (void)setScriptHandler: (NSString*)path;
- (void)handleScriptError: (NSDictionary*) errorInfo;
- (void)callScriptHandlerWithError: (SpellingError*)error;

@end

@implementation MyDocument

- (id)init
{
    self = [super init];
    if (self) {

		lastWindow = nil;
		spider = nil;
		cancelled = NO;
		misspellings = nil;
		status = idle;
		currentURL = nil;
		urlToLoad = nil;
		showAllURLS = NO;
		
		spellingLock = nil;
		scriptHandler = nil;
		
		[self setScriptHandler: [[DCProperties defaults] stringForKey: @"ScriptHandler"]];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
											   selector: @selector(defaultsChanged:)
												   name: NSUserDefaultsDidChangeNotification
												 object: nil];
    }
    return self;
}

- (void)dealloc
{
	[spider release];
	spider = nil;
	[misspellings release];
	misspellings = nil;
	[sortedPages release];
	sortedPages = nil;
	[urlToLoad release];
	urlToLoad = nil;
	[super dealloc];
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
	[docView setContentViewMargins: NSMakeSize(0, 0)];
	[spellingTree setRowHeight: 14.0];
	[[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(webViewLoaded:)
												 name: WebViewProgressFinishedNotification object: webView];
	if(urlToLoad != nil) {
		[urlEntryBox setStringValue: urlToLoad];
	}
	[self changeView: urlEntryWindow atSpeed: 0];
}

- (NSData *)dataRepresentationOfType:(NSString *)aType
{
	[self updateChangeCount: NSChangeCleared];
	return [self exportToHTML];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName
{
	return [NSString stringWithFormat: @"DreamCatcher: %@", ([urlEntryBox stringValue] == nil ? @"Untitled" : [urlEntryBox stringValue])];
}

/*
- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType
{
	if([aType isEqualToString: @"Internet Shortcut"]) {
		NSString* contents = [[NSString alloc] initWithData: data 
												   encoding: NSUTF8StringEncoding];
		NSLog(@"asked to load Internet Shortcut %@", contents);
		[contents release];
		return YES;
	}
	return NO;
}
*/


- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	FSRef ref;
    NSString* theFilePath = [absoluteURL path];
	if(theFilePath == nil) {
		outError = nil;
		return NO;
	}
	if (FSPathMakeRef ((const UInt8 *)[theFilePath fileSystemRepresentation], &ref, NULL) == noErr) 
    {
        short res = FSOpenResFile (&ref, fsRdPerm);
		OSErr err;
        if ((err = ResError()) == noErr) 
        {
            Handle urlHandle = Get1Resource('TEXT', 256);
			if(urlHandle != NULL) {
				NSString* urlText = [NSString stringWithCString: *urlHandle 
													   encoding: NSMacOSRomanStringEncoding];
				NSLog(@"got handle and url is %@", urlText);
				urlToLoad = [urlText retain];
				[urlEntryBox setStringValue: urlToLoad];
				CloseResFile(res);
				return YES;
			} else {
				NSLog(@"didn't get handle");
				*outError = [NSError errorWithDomain: NSOSStatusErrorDomain
												code: ResError() 
										   userInfo: nil];
				CloseResFile(res);
				return NO;
			}
        } else {
			*outError = [NSError errorWithDomain: NSOSStatusErrorDomain
											code: ResError() 
										userInfo: nil];
		}
    } else {
		outError = nil;
		return NO;
	}
	return NO;
}

- (IBAction)urlEntryBoxAction: (id)sender
{
	
}

- (IBAction)beginButtonAction: (id)sender
{
	[spider release];
	spider = nil;
	[misspellings release];
	misspellings = nil;
	[sortedPages release];
	sortedPages = nil;
	
	NSString* baseString = [urlEntryBox stringValue];
	if([baseString rangeOfString: @"://"].location == NSNotFound) {
		baseString = [NSString stringWithFormat: @"http://%@", baseString];
		[urlEntryBox setStringValue: baseString];
	}
	
	NSURL* base = nil;
	@try {
		base = [NSURL URLWithString: [urlEntryBox stringValue]];
	} @catch (id anException) {
		base = nil;
	}
	if(base == nil) {
		alertBox("Cannot spellcheck site",
				 [[NSString stringWithFormat: @"\"%@\" is not a valid URL.", [urlEntryBox stringValue]] cString]);
		return;
	}
	
	cancelled = NO;
	[progressBox setString: @""];
	[urlDisplayBox setStringValue: [urlEntryBox stringValue]];
	[self changeView: progressWindow atSpeed: 0.5];	
	
	int depth = [[DCProperties defaults] integerForKey: @"SpiderDepth"];
	NSLog(@"using max spider depth of %d", depth);
	spider = [[Spider alloc] initWithBaseURL: [NSURL URLWithString: [urlEntryBox stringValue]]
							  maxSearchDepth: depth];
	[spider addProgressListener: self];
	
	[NSThread detachNewThreadSelector: @selector(watchSpider) 
							 toTarget: self 
						   withObject: nil];
	
	[progressSpinner startAnimation: self];
	
}

- (IBAction)cancelButtonAction: (id)sender
{
	cancelled = YES;
	if(status == spidering) {
		[spider cancel];
	}
	[misspellings release];
	misspellings = nil;
	[sortedPages release];
	sortedPages = nil;
	
	[progressSpinner stopAnimation: self];
	[self changeView: urlEntryWindow atSpeed: 0.5];
}

- (IBAction)spellingTreeAction: (id)sender
{
	
}

- (void)changeView: (NSWindow*)window atSpeed: (double)duration
{
	// just do it immediately
	if(duration < 0.05) {
		NSWindow* viewWindow = docWindow;
		NSBox* windowView = docView;
		
		if(lastWindow != nil) {
			[lastWindow setContentView: [windowView contentView]];
		}
		
		[viewWindow setMaxSize: [window maxSize]];
		[viewWindow setMinSize: [window minSize]];
		
		//[windowView setFrame: [[window contentView] frame]];
		
		NSRect newFrame = [window frame];
		NSRect oldFrame = [viewWindow frame];
		newFrame.origin.y = oldFrame.origin.y - (newFrame.size.height - oldFrame.size.height);
		newFrame.origin.x = oldFrame.origin.x;
		
		[viewWindow setFrame: newFrame
					 display: YES];
		[windowView setContentView: [window contentView]];
		[windowView setBounds: [[window contentView] bounds]];
//		[windowView sizeToFit];

		[viewWindow setTitle: [window title]];
		lastWindow = window;
		
	} else {
		
		[[window contentView] setHidden: NO];
		NSWindow* viewWindow = docWindow;
		NSBox* windowView = docView;
		[viewWindow setMaxSize: [window maxSize]];
		[viewWindow setMinSize: [window minSize]];
		
		NSView* savedView = [windowView contentView];
		[windowView setContentView: nil];
		
		NSRect newFrame = [window frame];
		NSRect oldFrame = [viewWindow frame];
		newFrame.origin.y = oldFrame.origin.y - (newFrame.size.height - oldFrame.size.height);
		newFrame.origin.x = oldFrame.origin.x;

// I haven't been able to get the view fading stuff in NSViewAnimation to
// work, plus it seems like the frame resizing stuff in it isn't as exact as it
// should be.  Hence why it is #ifdef-ed out like this.
#ifdef USE_NSVIEWANIMATION
		NSLog(@"Using NSViewAnimation for view transition");
		NSRect contentViewFrame = [[window contentView] frame];
		NSDictionary* fadeOutAndResizeBox = [NSDictionary 
			dictionaryWithObjectsAndKeys:	
				windowView, NSViewAnimationTargetKey,
				[NSValue valueWithBytes: &contentViewFrame objCType: @encode(NSRect)], NSViewAnimationEndFrameKey,
				NSViewAnimationEffectKey, NSViewAnimationFadeOutEffect, nil];
				
		NSDictionary* resizeWindow = [NSDictionary
			dictionaryWithObjectsAndKeys: 
			viewWindow, NSViewAnimationTargetKey,
			[NSValue valueWithBytes: &newFrame objCType: @encode(NSRect)], NSViewAnimationEndFrameKey, nil];
		
		NSViewAnimation* anim1 = [[NSViewAnimation alloc] initWithViewAnimations:
			[NSArray arrayWithObjects: fadeOutAndResizeBox, resizeWindow, nil]];
		[anim1 setDuration: duration / 2.0];
		
		[anim1 setAnimationBlockingMode: NSAnimationBlocking];
		[anim1 startAnimation];
		[anim1 release];
#else
		[viewWindow setFrame: newFrame
					 display: YES
					 animate: YES];
#endif
		
		if(lastWindow != nil) {
			[lastWindow setContentView: savedView];
		}
		
		[windowView setContentView: [window contentView]];
#ifdef USE_NSVIEWANIMATION
		[[windowView contentView] setHidden: YES];
		
		NSDictionary* fadeIn = [NSDictionary dictionaryWithObjectsAndKeys: 
			windowView, NSViewAnimationTargetKey,
			NSViewAnimationEffectKey, NSViewAnimationFadeInEffect, nil];
		
		NSViewAnimation* anim2 = [[NSViewAnimation alloc] initWithViewAnimations: 
			[NSArray arrayWithObjects: fadeIn, nil]];
		
		[anim2 setDuration: duration / 2.0];
		[anim2 setAnimationBlockingMode: NSAnimationBlocking];
		[anim2 startAnimation];
		[anim2 release];
#endif
		[viewWindow setTitle: [window title]];
		lastWindow = window;
	}
	
}

- (void)watchSpider
{
	status = spidering;
	[spider blockingRun];
	status = idle;
	if(!cancelled) {
		[self performSelectorOnMainThread: @selector(spiderFinished) 
							   withObject: nil 
							waitUntilDone: NO];
	}
}

- (void)spiderFinished
{
	NSLog(@"spider finished");
	[cancelButton setEnabled: NO];
	status = spellchecking;
	[self addProgress: [@"Checking spelling" retain]];
	[self populateSpelling];	
}

- (void)addProgress: (NSString*)progressItem
{
	[[[progressBox textStorage] mutableString] appendFormat: @"%@\n", progressItem];
	NSRange theEnd;
    theEnd = NSMakeRange([[progressBox textStorage] length], 0);
    [progressBox scrollRangeToVisible: theEnd];
	[progressItem release];
}

- (void)populateSpelling
{
	[NSThread detachNewThreadSelector: @selector(spellcheckWorker) 
							 toTarget: self 
						   withObject: nil];
}

- (void)spellingFinished
{
	sortedPages = [[misspellings allKeys] retain];
	[self buildSpellingContextualMenu];
	[spellingTree setDelegate: self];
	[spellingTree setDataSource: self];
	[spellingTree reloadData];
	[self updateChangeCount: NSChangeDone];
	[self changeView: resultsWindow atSpeed: 0.5];
	[progressSpinner stopAnimation: self];
}

- (void)spellcheckWorker
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	[spellingLock lockWhenCondition: 0];
	misspellings = [[Spellchecker checkSiteSpelling: spider] retain];
	[spellingLock unlockWithCondition: 1];
	[self performSelectorOnMainThread: @selector(spellingFinished) 
						   withObject: nil waitUntilDone: NO];
	[pool release];
}

- (void)buildSpellingContextualMenu
{
	NSMenu* contextualMenu = [[NSMenu alloc] initWithTitle: @"Spelling Tree Contextual Menu"];
	[[contextualMenu addItemWithTitle: @"Ignore" 
							  action: @selector(ignore:) 
						keyEquivalent: @""] setTarget: self];
	[[contextualMenu addItemWithTitle: @"Ignore All" 
							   action: @selector(ignoreAll:) 
						keyEquivalent: @""] setTarget: self];
	[[contextualMenu addItemWithTitle: @"Add Word" 
							   action: @selector(addWord:) 
						keyEquivalent: @""] setTarget: self];
	[[contextualMenu addItemWithTitle: @"Fix Misspelling" 
							   action: @selector(fixMisspelling:) 
						keyEquivalent: @""] setTarget: self];
	[[contextualMenu itemAtIndex: 0] setTag: 7000];
	[[contextualMenu itemAtIndex: 1] setTag: 7001];
	[[contextualMenu itemAtIndex: 2] setTag: 7002];
	[[contextualMenu itemAtIndex: 3] setTag: 7005];
	[spellingTree setMenu: contextualMenu];
	[contextualMenu release];
}

- (void)fetchingURL: (NSURL*)url
         fromSpider: (Spider*)spider
{
	[self performSelectorOnMainThread: @selector(addProgress:) 
						   withObject: [[NSString alloc] initWithFormat: @"Checking url: %@", [url absoluteString]]
						waitUntilDone: NO];
}

- (int)outlineView: (NSOutlineView *)outlineView numberOfChildrenOfItem: (id)item
{
	if(item == nil) {
		if(showAllURLS) {
			return [sortedPages count];
		} else {
			int count = 0;
			for(int i = 0; i < [sortedPages count]; i++) {
				if(![self pageIsIgnored: i]) count++;
			}
			return count;
		}
	} else if([item isKindOfClass: [NSURL class]]) {
		// url header
		NSArray* children = [misspellings objectForKey: item];
		if(children != nil) {
			//return [children count];
			int count = 0;
			for(unsigned int i = 0; i < [children count]; i++) {
				SpellingError* error = [children objectAtIndex: i];
				if(![error ignore]) count++;
			}
			return count;
		} else {
			return 0;
		}
	} else if([item isKindOfClass: [SpellingError class]]) {
		// misspelling
		return [[item suggestions] count];
	} else {
		// suggestion
		return 0;
	}
}

- (BOOL)pageIsIgnored: (int)indexOfPage
{
	return [self pageIsIgnoredByURL: [sortedPages objectAtIndex: indexOfPage]];
}

- (BOOL)pageIsIgnoredByURL: (NSURL*)page
{
	NSArray* children = [misspellings objectForKey: page];
	if(children != nil) {
		for(int j = 0; j < [children count]; j++) {
			SpellingError* error = [children objectAtIndex: j];
			if(![error ignore]) {
				return NO;
			}
		}
	}
	return YES;
}

- (int)countMisspellingsForURL: (NSURL*)url
{
	int count = 0;
	NSArray* children = [misspellings objectForKey: url];
	if(children != nil) {
		for(int j = 0; j < [children count]; j++) {
			SpellingError* error = [children objectAtIndex: j];
			if(![error ignore]) {
				count++;
			}
		}
	}
	return count;
}

- (BOOL)outlineView: (NSOutlineView *)outlineView isItemExpandable: (id)item
{
	return [self outlineView: outlineView numberOfChildrenOfItem: item] > 0;
}

- (id)outlineView:(NSOutlineView *)outlineView
			child:(int)index
		   ofItem:(id)item
{
	if(item == nil) {
		// Pages
		if(index < [sortedPages count] && index >= 0) {
			if(showAllURLS) {
				return [sortedPages objectAtIndex: index];
			} else {
			int count = 0;
				for(int i = 0; i < [sortedPages count]; i++) {
					if(![self pageIsIgnored: i]) {
						count++;
						if(count-1 == index) return [sortedPages objectAtIndex: i];
					}
				}
			}
		} else {
			return nil;
		}
	} else if([item isKindOfClass: [NSURL class]]) {
		// SpellingError
		NSArray* children = [misspellings objectForKey: item];
		if(children != nil) {
			int count = 0;
			for(unsigned int i = 0; i < [children count]; i++) {
				SpellingError* error = [children objectAtIndex: i];
				if(![error ignore]) count++;
				if(count-1 == index) return error;
			}
			return nil;
		} else {
			return nil;
		}
	} else if([item isKindOfClass: [SpellingError class]]) {
		// suggestion
		return [[item suggestions] objectAtIndex: index];
	} 
	return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView
    objectValueForTableColumn:(NSTableColumn *)tableColumn
		   byItem:(id)item
{
	if(item == nil) {
		return nil;
	} else if([item isKindOfClass: [NSURL class]]) {
		// Page
		int errorCount = [self countMisspellingsForURL: item];
		NSString* displayString = 
			[NSString stringWithFormat: @"%@ (%d %@)", 
				[item absoluteString], errorCount, errorCount == 1 ? @"error" : @"errors"];
		NSMutableAttributedString* ret = 
			[[NSMutableAttributedString alloc] initWithString: displayString
								   attributes: 
				[NSDictionary dictionaryWithObjectsAndKeys: 
					[NSFont userFontOfSize: 11.0], NSFontAttributeName,
					[NSColor blueColor], NSForegroundColorAttributeName,
					[NSNumber numberWithInt: 1], NSUnderlineStyleAttributeName,
					nil]];
		return [ret autorelease];
	} else if([item isKindOfClass: [SpellingError class]]) {
		// SpellingError 
		NSMutableAttributedString* ret = 
		[[NSMutableAttributedString alloc] initWithString: [NSString stringWithFormat: @"%@ (%d suggestion%s)", [item misspelling], [[item suggestions] count], ([[item suggestions] count] != 1 ? "s" : "")]
								   attributes: 
				[NSDictionary dictionaryWithObjectsAndKeys: 
					[NSFont userFontOfSize: 11.0], NSFontAttributeName, nil]];
		return [ret autorelease];
	} else {
		// Suggestion
		NSMutableAttributedString* ret = 
		[[NSMutableAttributedString alloc] initWithString: item
							   attributes: 
			[NSDictionary dictionaryWithObjectsAndKeys: 
				[NSFont userFontOfSize: 11.0], NSFontAttributeName, nil]];
		return [ret autorelease];
	}
	
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	highlightError = nil;
	id item = [spellingTree itemAtRow: [spellingTree selectedRow]];
	if(item != nil) {
		if([item isKindOfClass: [NSURL class]]) {
			[webTabView selectTabViewItemAtIndex: 1];
			[loadingPageProgressSpinner startAnimation: self];
			currentURL = item;
			[[webView mainFrame] loadRequest: [NSURLRequest requestWithURL: item]];
			[spellingTree expandItem: item];
		} else if([item isKindOfClass: [SpellingError class]]) {
			[self selectError: item];	
			[spellingTree expandItem: item];
		} else {
			// its a suggestion, so walk back up the rows until something else is encountered
			int currentRow = [spellingTree selectedRow];
			while(currentRow >= 0) {
				if ([item isKindOfClass: [NSURL class]]) {
					[[webView mainFrame] loadRequest: [NSURLRequest requestWithURL: item]];
					return;
				} else if([item isKindOfClass: [SpellingError class]]) {
					[self selectError: item];
					return;
				} else {
					currentRow--;
					item = [spellingTree itemAtRow: currentRow];
				}
			}
		}
	}
}

- (void)selectError: (SpellingError*)error
{
	highlightError = error;
	
	if(currentURL != nil && [currentURL isEqual: [[error page] url]]) {
		[self doHighlightError];
	} else {
		[webTabView selectTabViewItemAtIndex: 1];
		[loadingPageProgressSpinner startAnimation: self];
		[[webView mainFrame] loadRequest: [NSURLRequest requestWithURL: [[error page] url]]];
	}
	currentURL = [[error page] url];
}

- (void)webViewLoaded: (NSNotification*)userInfo
{
	[loadingPageProgressSpinner stopAnimation: self];
	[webTabView selectTabViewItemAtIndex: 0];
	[self doHighlightError];
}

- (void)doHighlightError
{
	if(highlightError != nil) {
		[webView setSelectedDOMRange: nil affinity: NSSelectionAffinityDownstream];
		for(int i = 1; i <= [highlightError occurrenceNumber]; i++) {
			[webView searchFor: [highlightError misspelling] direction: YES caseSensitive: YES wrap: NO];
		}		
	}
}

- (void)ignore: (id)sender
{
	SpellingError* error = [self currentlySelectedError];
	if(error != nil) {
		[error setIgnore: YES];
		[[self undoManager] registerUndoWithTarget: self 
										  selector: @selector(unignore:) 
											object: error];
		//[spellingTree reloadItem: [[error page] url] reloadChildren: YES];
		[spellingTree reloadData];
	}
}

- (IBAction)ignoreAll: (id)sender
{
	NSString* misspelling = [self ignoreAllImpl];
	if(misspelling != nil) {
		[[self undoManager] registerUndoWithTarget: self 
										  selector: @selector(unignoreAll:) 
											object: misspelling];
	}
}

- (IBAction)addWord: (id)sender
{
	NSString* misspelling = [self ignoreAllImpl];
	if(misspelling != nil) {
		[Spellchecker addWord: misspelling];
		[[self undoManager] registerUndoWithTarget: self 
										  selector: @selector(unAddWord:) 
											object: misspelling];
	}
}

- (NSString*)ignoreAllImpl
{
	SpellingError* localError = [self currentlySelectedError];
	if(localError != nil) {
		NSString* misspelling = [localError misspelling];
		for(int i = 0; i < [sortedPages count]; i++) {
			NSArray* errors = [misspellings objectForKey: [sortedPages objectAtIndex: i]];
			if(errors != nil) {
				for(int j = 0; j < [errors count]; j++) {
					SpellingError* error = [errors objectAtIndex: j];
					if([[error misspelling] isEqualToString: misspelling]) {
						[error setIgnore: YES];
					}
				}
			}
		
		}
		[spellingTree reloadData];
		return misspelling;
	}
	return nil;
}

- (void)unignore: (SpellingError*)error
{
	[error setIgnore: NO];
	[spellingTree reloadData];
}

- (void)unignoreAll: (NSString*)misspelling
{
	// gotsta search the whole shebang and then reverse the changes
	for(int i = 0; i < [sortedPages count]; i++) {
		NSArray* errors = [misspellings objectForKey: [sortedPages objectAtIndex: i]];
		if(errors != nil) {
			for(int j = 0; j < [errors count]; j++) {
				SpellingError* error = [errors objectAtIndex: j];
				if([[error misspelling] isEqualToString: misspelling]) {
					[error setIgnore: NO];
				}
			}
		}
	}
	[spellingTree reloadData];
}

- (void)unAddWord: (NSString*)word
{
	[Spellchecker unAddWord: word];
	[self unignoreAll: word];
}

- (SpellingError*)currentlySelectedError
{
	id item = [spellingTree itemAtRow: [spellingTree selectedRow]];
	if(item == nil) {
		return nil;
	} else if([item isKindOfClass: [NSURL class]]) {
		return nil;
	} else if([item isKindOfClass: [SpellingError class]]) {
		return item;
	} else {
		/*
		int currentRow = [spellingTree selectedRow];
		while(currentRow >= 0) {
			if ([item isKindOfClass: [NSURL class]]) {
				return nil;
			} else if([item isKindOfClass: [SpellingError class]]) {
				return item;
			} else {
				currentRow--;
				item = [spellingTree itemAtRow: currentRow];
			}
		}*/
		return nil;
	}
}

- (IBAction)toggleShowAllURLS: (id)sender
{
	showAllURLS = !showAllURLS;
	id <NSMenuItem> item = nil;
	if([sender conformsToProtocol: @protocol(NSMenuItem)]) {
		item = sender;
	}
	if(showAllURLS && item != nil) {
		[item setTitle: @"Hide pages that do not contain misspellings"];
		// this doesn't work for some reason ... vexing >:-/
		//[[[NSApp mainMenu] itemWithTag: 7003] setTitle: @"Hide pages that do not contain misspellings"];
	} else if(item != nil) {
		[item setTitle: @"Show pages that do not contain misspellings"];
		//[[[NSApp mainMenu] itemWithTag: 7003] setTitle: @"Show pages that do not contain misspellings"];
	}
	[spellingTree reloadData];
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
	int tag = [anItem tag];
	switch (tag) {
		case 7003:
			if(showAllURLS) {
				[(id <NSMenuItem>)anItem setTitle: @"Hide pages that do not contain misspellings"];
			} else {
				[(id <NSMenuItem>)anItem setTitle: @"Show pages that do not contain misspellings"];
			}
		case 6683:
		case 7004:
			return misspellings != nil;
		case 7000:
		case 7001:
		case 7002:
			return (misspellings != nil) && ([self currentlySelectedError] != nil);
		case 7005:
			return (misspellings != nil) && ([self currentlySelectedError] != nil) && (scriptHandler != nil);
		default:
			return YES;
	}
}

- (NSData*)exportToHTML
{
	NSMutableString* html = [[NSMutableString alloc] init];
	[html appendString: 
		@"<?xml version=\"1.0\"?>\n"
		@"<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"\n"
		@"\"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n"
		@"<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\">\n"];
	[html appendString: @"<head>\n"];
	[html appendFormat: @"<title>DreamCatcher spelling results for %@</title>\n", [urlEntryBox stringValue]];
	[html appendFormat: @"<meta name=\"generator\" content=\"%@\"/>\n", [[DCProperties defaults] stringForKey: @"User-Agent"]];
	[html appendString: @"</head>\n"];
	
	[html appendString: @"<body>\n"];
	
	[html appendString: @"<ul>\n"];
	NSEnumerator* e = [sortedPages objectEnumerator];
	NSURL* url = nil;
	while((url = [e nextObject]) != nil) {
		if([self pageIsIgnoredByURL: url]) continue;
		[html appendString: @"<li>\n"];
		[html appendFormat: @"<a href=\"%@\" target=\"_blank\">%@</a>\n", [url absoluteString], [url absoluteString]];
		
		NSArray* errorsList = [misspellings objectForKey: url];
		if(errorsList != nil) {
			[html appendString: @"<ul>\n"];
			
			NSEnumerator* errorsEnum = [errorsList objectEnumerator];
			SpellingError* error = nil;
			while((error = [errorsEnum nextObject]) != nil) {
				if([error ignore]) continue;
				[html appendString: @"<li>\n"];
				
				[html appendString: [error misspelling]];
				if([[error suggestions] count] > 0) {
					[html appendString: @"<ul>\n"];
						[html appendString: @"<li>\n"];
						[html appendString: @"suggestions: "];
						
						NSArray* suggestions = [error suggestions];
						for(int i = 0; i < [suggestions count]; i++) {
							if(i < ([suggestions count] - 1)) {
								[html appendFormat: @"%@, ", [suggestions objectAtIndex: i]];
							} else {
								[html appendString: [suggestions objectAtIndex: i]];
							}
						}
						
						[html appendString: @"</li>\n"];
					[html appendString: @"</ul>\n"];
				} else {
					[html appendString: @"<ul>\n"];
					[html appendString: @"<li>\n"];
					[html appendString: @"No suggestions."];

					[html appendString: @"</li>\n"];
					[html appendString: @"</ul>\n"];

				}
				
				[html appendString: @"</li>\n"];
			}
			
			[html appendString: @"</ul>\n"];
		} else {
			[html appendString: @"<ul>\n"];
			[html appendString: @"<li>No errors.</li>\n"];
			[html appendString: @"</ul>\n"];
		}
		
		[html appendString: @"</li>\n"];
	}
	[html appendString: @"</ul>\n"];
	
	[html appendString: @"</body>\n"];
	
	[html appendString: @"</html>\n"];

	NSData *data = [html dataUsingEncoding: NSUTF8StringEncoding];
	[html release];
	return data;
}


- (IBAction)showPreferences: (id)sender
{
	if(preferences == nil) {
		preferences = [[PreferencesController alloc] initWithWindowNibName: @"Preferences"];
	}
	[preferences showWindow: self];
}

- (void)defaultsChanged: (NSNotification*)note
{
	[self setScriptHandler: [[DCProperties defaults] stringForKey: @"ScriptHandler"]];
}

- (void)setScriptHandler: (NSString*)path
{
	if(path == nil) {
		[scriptHandler release];
		scriptHandler = nil;
		return;
	}
	NSDictionary* errorInfo = nil;
	[scriptHandler release];
	scriptHandler = [[NSAppleScript alloc] initWithContentsOfURL: [NSURL fileURLWithPath: path] error: &errorInfo];
    
    /* See if there were any errors loading the script */
    if (!scriptHandler || errorInfo) {
        [self handleScriptError: errorInfo];
		scriptHandler = nil;
    }
	
}

- (IBAction)fixMisspelling: (id)sender
{
	SpellingError* localError = [self currentlySelectedError];
	if(localError != nil) {
		[self callScriptHandlerWithError: localError];
	}
}

- (void) handleScriptError: (NSDictionary *) errorInfo {
    NSString *errorMessage = [errorInfo objectForKey: NSAppleScriptErrorMessage];
    NSNumber *errorNumber = [errorInfo objectForKey: NSAppleScriptErrorNumber];
	
    NSRunAlertPanel(NSLocalizedString(@"Script Error", @"Title on script error window."), [NSString stringWithFormat: @"%@: %@", NSLocalizedString(@"The script produced an error", @"Message on script error window."), errorNumber, errorMessage], NSLocalizedString(@"OK", @""), nil, nil);
}

- (void)callScriptHandlerWithError: (SpellingError*)error
{
	if(scriptHandler == nil) return;
	
	/* the handler in the AppleScript looks like this: 
	
	on error_found(inFile, onHost, misspelling, suggestions, occurrence)
	
	where the following are the types of the arguments:
	inFile: string
	onHost: string
	misspelling: string
	suggestions: list of strings
	occurence: integer (1 based, so the first occurrence is 1, not 0)
	
	*/
	
	NSString* inFile = [[[error page] url] path];
	NSString* onHost = [[[error page] url] host];
	NSString* misspelling = [error misspelling];
	NSAppleEventDescriptor* suggestions = [NSAppleEventDescriptor listDescriptor];
	for(int i = 0; i < [[error suggestions] count]; i++) {
		[suggestions insertDescriptor: 
			[NSAppleEventDescriptor descriptorWithString: [[error suggestions] objectAtIndex: i]]
							  atIndex: i + 1];
	}	
	int occurrence = [error occurrenceNumber];
	
	NSAppleEventDescriptor* arguments = [NSAppleEventDescriptor listDescriptor];
	[arguments insertDescriptor: [NSAppleEventDescriptor descriptorWithString: inFile]
						atIndex: 1];
	[arguments insertDescriptor: [NSAppleEventDescriptor descriptorWithString: onHost]
						atIndex: 2];
	[arguments insertDescriptor: [NSAppleEventDescriptor descriptorWithString: misspelling]
						atIndex: 3];
	[arguments insertDescriptor: suggestions
						atIndex: 4];
	[arguments insertDescriptor: [NSAppleEventDescriptor descriptorWithInt32: occurrence]
						atIndex: 5];
	
	NSDictionary* errorInfo = nil;
	NSAppleEventDescriptor* result = [scriptHandler callHandler: kErrorHandler 
												  withArguments: arguments
													  errorInfo: &errorInfo];
	
	if(errorInfo != nil) {
		[self handleScriptError: errorInfo];
		return;
	}
	
	// I use the result to determine whether or not the applescript handler
	// believes that it has fixed the error.
	if([result booleanValue]) {
		[error setIgnore: YES];
		[spellingTree reloadData];
		currentURL = nil;
		[self selectError: error];
	}
			
}

@end
