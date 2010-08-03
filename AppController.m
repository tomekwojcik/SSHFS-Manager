/**
 *  AppController.m
 *  SSHFS Manager
 *
 *  Created by Tomek Wójcik on 7/15/10.
 *  Copyright 2010 Tomek Wójcik. All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without modification, are
 *  permitted provided that the following conditions are met:
 *  
 *  1. Redistributions of source code must retain the above copyright notice, this list of
 *  conditions and the following disclaimer.
 *  
 *  2. Redistributions in binary form must reproduce the above copyright notice, this list
 *  of conditions and the following disclaimer in the documentation and/or other materials
 *  provided with the distribution.
 *  
 *  THIS SOFTWARE IS PROVIDED BY Tomek Wójcik ``AS IS'' AND ANY EXPRESS OR IMPLIED
 *  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 *  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Tomek Wójcik OR
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 *  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 *   SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 *  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 *  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *  The views and conclusions contained in the software and documentation are those of the
 *  authors and should not be interpreted as representing official policies, either expressed
 *  or implied, of Tomek Wójcik.
 */

#import "AppController.h"
#import "BTHMenuItem.h"

@implementation AppController
-(id)init {
	if ((self = [super init])) {
		statusItem = nil;
		statusItemImage = nil;
		currentTab = nil;
		hasSshfs = NO;
		isWorking = NO;
		currentOperationType = BTHNoopOperationType;
		lastMountedLocalPath = nil;
		lastUnmountedLocalPath = nil;
		autoUpdateTimer = nil;
		currentTask = nil;
	} // eof if()
	
	return self;
} // eof init

-(void)dealloc {
	[self removeObserver:self forKeyPath:@"currentTab"];
	[sharesController removeObserver:self forKeyPath:@"selectionIndex"];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSTaskDidTerminateNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:nil];
	[[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"sshfsPath"];
	[[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"autoUpdate"];
	[[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"autoUpdateInterval"];
	
	[[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
	
	[statusItem release]; statusItem = nil;
	[statusItemImage release]; statusItemImage = nil;
	[currentTab release]; currentTab = nil;
	[lastMountedLocalPath release]; lastMountedLocalPath = nil;
	[lastUnmountedLocalPath release]; lastUnmountedLocalPath = nil;
	
	if (autoUpdateTimer != nil) {
		[autoUpdateTimer invalidate]; [autoUpdateTimer release]; autoUpdateTimer = nil;
	} // eof if()
	
	[currentTask release]; currentTask = nil;
	
	[super dealloc];
} // eof dealloc

-(void)awakeFromNib {
	NSBundle *mainBundle = [NSBundle mainBundle];
	
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *defaultsPath = [mainBundle pathForResource:@"userDefaults" ofType:@"plist"];
    
    if (defaultsPath != nil) {
        NSDictionary *defaultsDictionary = [[NSDictionary alloc] initWithContentsOfFile:defaultsPath];
        [preferences registerDefaults:defaultsDictionary];
        [defaultsDictionary release];
    } // eof if()
	[preferences synchronize];	
	
	[self addObserver:self forKeyPath:@"currentTab" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:@selector(tabChangedFrom:to:)];
	[sharesController addObserver:self forKeyPath:@"selectionIndex" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:@selector(sharesSelectionChangedFrom:to:)];
	[preferences addObserver:self forKeyPath:@"sshfsPath" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:@selector(sshfsPathChangedFrom:to:)];
	[preferences addObserver:self forKeyPath:@"autoUpdate" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:@selector(autoUpdateChangedFrom:to:)];
	[preferences addObserver:self forKeyPath:@"autoUpdateInterval" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:@selector(autoUpdateIntervalChangedFrom:to:)];
	
	NSSortDescriptor *sharesSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease];
	[sharesController setSortDescriptors:[NSArray arrayWithObject:sharesSortDescriptor]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(checkATaskStatus:)
												 name:NSTaskDidTerminateNotification
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:nil];
	
	NSString *sshfsPath = [preferences valueForKey:@"sshfsPath"];
	if ((sshfsPath == nil) || ([sshfsPath isEqualToString:@""] == YES)) {
		[self findSshfs];
	} else {
		[self setHasSshfs:YES];
	} // eof if()
	
	NSString *statusItemImgPath = [mainBundle pathForResource:@"drive_web" ofType:@"png"];
	statusItemImage = [[NSImage alloc] initWithContentsOfFile:statusItemImgPath];
	
	statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
	[statusItem setMenu:[self statusItemMenu]];
	[statusItem setImage:statusItemImage];
	[statusItem setHighlightMode:YES];
	[statusItem setLength:25.0];
	[statusItem retain];
	
	if ([preferences boolForKey:@"autoUpdate"] == YES) {
		[self setUpAutoUpdateTimer];
	} // eof if()
} // eof awakeFromNib

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)selector {
	[self performSelector:(SEL)selector withObject:[change objectForKey:@"old"] withObject:[change objectForKey:@"new"]];
} // eof observeValueForKeyPath:ofObject:change:context:

@synthesize currentTab;
@synthesize hasSshfs;
@synthesize isWorking;
@synthesize lastMountedLocalPath;
@synthesize lastUnmountedLocalPath;

-(void)tabChangedFrom:(NSString *)oldTab to:(NSString *)newTab {
	if ([newTab isEqualToString:@"Shares"]) {
		[shareDrawer open];
		[self sharesSelectionChangedFrom:nil to:nil];
	} else {
		[shareDrawer close];
	} // eof if()
} // tabChangedFrom:to:

-(void)sharesSelectionChangedFrom:(id)oldIndex to:(id)newIndex {
	if ([preferencesWindow isVisible]) {
		if ([sharesController selectionIndex] != NSNotFound) {
			[shareDrawer open];
		} else {
			[shareDrawer close];
		} // eof if()
	} // eof if()
} // eof sharesSelectionChanged:

-(void)sshfsPathChangedFrom:(NSString *)oldPath to:(NSString *)newPath {
	if ((newPath != nil) && ([newPath isEqualToString:@""] == NO)) {
		[self setHasSshfs:YES];
	} else {
		[self setHasSshfs:NO];
	} // eof if()
	
	//[self refreshStatusItemMenu];
} // eof sshfsPathChangedFrom:to:

-(void)localPathBrowseSheetDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode  contextInfo:(void *)contextInfo {
	if (returnCode == NSOKButton) {
		NSArray *filenames = [panel filenames];
		if ([filenames count] > 0) {
			NSString *filename = [filenames objectAtIndex:0];
			NSManagedObject *currentShare = [[sharesController selectedObjects] objectAtIndex:0];
			[currentShare setValue:filename forKey:@"localPath"];
			
			NSString *volumeName = [currentShare valueForKey:@"volumeName"];
			if ((volumeName == nil) || ([volumeName isEqualToString:@""] == YES)) {
				[currentShare setValue:[filename lastPathComponent] forKey:@"volumeName"];
			} // eof if()
		} // eof if()
	} // eof if()
} // eof localPathBrowseSheetDidEnd:returnCode:contextInfo:

-(NSMenu *)statusItemMenu {
	NSMenu *myStatusItemMenu = [[[NSMenu alloc] init] autorelease];
	[myStatusItemMenu setAutoenablesItems:NO];
	
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	NSManagedObjectContext *sharesContext = [appDelegate managedObjectContext];
	NSManagedObjectModel *shareModel = [appDelegate managedObjectModel];
	NSEntityDescription *shareEntity = [[shareModel entities] objectAtIndex:0];
	
	NSFetchRequest *sharesFetchRequest = [[[NSFetchRequest alloc] init] autorelease];
	[sharesFetchRequest setPredicate:nil];
	NSSortDescriptor *sharesSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease];
	[sharesFetchRequest setSortDescriptors:[NSArray arrayWithObject:sharesSortDescriptor]];
	[sharesFetchRequest setEntity:shareEntity];
	
	NSError *myError = nil;
	NSArray *currentShares = [sharesContext executeFetchRequest:sharesFetchRequest error:&myError];
	
	if (myError != nil) {
		BOOL errorResult = [[NSApplication sharedApplication] presentError:myError];
		[[NSApplication sharedApplication] terminate:nil];
	} // eof if()
	
	if ([currentShares count] == 0) {
		NSMenuItem *noVolumesItem = [[[NSMenuItem alloc] initWithTitle:@"No volumes" action:nil keyEquivalent:@""] autorelease];
		[noVolumesItem setEnabled:NO];
		[myStatusItemMenu addItem:noVolumesItem];
	} else {
		NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
		NSArray *mountedFileSystems = [workspace mountedLocalVolumePaths];
		
		NSEnumerator *sharesEnum = [currentShares objectEnumerator];
		NSManagedObject *currentObject = nil;
		NSMutableDictionary *currentData = nil;
		while((currentObject = [sharesEnum nextObject])) {
			BTHMenuItem *currentShareItem = [[[BTHMenuItem alloc] initWithTitle:[currentObject valueForKey:@"name"] action:@selector(doMountShare:) keyEquivalent:@""] autorelease];
			[currentShareItem setTarget:self];
			currentData = [NSMutableDictionary dictionaryWithCapacity:1];
			[currentData setObject:[currentObject valueForKey:@"host"] forKey:@"host"];
			[currentData setObject:[currentObject valueForKey:@"login"] forKey:@"login"];
			[currentData setObject:[currentObject valueForKey:@"options"] forKey:@"options"];
			[currentData setObject:[currentObject valueForKey:@"port"] forKey:@"port"];
			
			NSString *remotePath = [currentObject valueForKey:@"remotePath"];
			if (remotePath != nil) {
				[currentData setObject:remotePath forKey:@"remotePath"];
			} // eof if()
			
			[currentData setObject:[currentObject valueForKey:@"volumeName"] forKey:@"volumeName"];
			
			NSString *localPath = [currentObject valueForKey:@"localPath"];
			[currentData setObject:localPath forKey:@"localPath"];
			if ((currentOperationType == BTHMountShareOperationType) && ([localPath isEqualToString:[self lastMountedLocalPath]] == YES)) {
				[currentShareItem setState:NSOnState];
			} else if ((currentOperationType == BTHUnmountShareOperationType) && ([localPath isEqualToString:[self lastUnmountedLocalPath]] == YES)) {
				[currentShareItem setState:NSOffState];
			} else if ([mountedFileSystems containsObject:localPath] == YES) {
				[currentShareItem setState:NSOnState];
			} else {
				[currentShareItem setState:NSOffState];
			} // eof if()
			
			[currentShareItem bind:@"enabled" toObject:self withKeyPath:@"hasSshfs" options:nil];
			[currentShareItem bind:@"enabled2"
						  toObject:self
					   withKeyPath:@"isWorking"
						   options:[NSDictionary dictionaryWithObject:NSNegateBooleanTransformerName forKey:NSValueTransformerNameBindingOption]];
			
			[currentShareItem setItemData:currentData];
			[myStatusItemMenu addItem:currentShareItem];
		} // eof while()
	} // eof if()
	
	NSMenuItem *separatorItem = [NSMenuItem separatorItem];
	[myStatusItemMenu addItem:separatorItem];
	
	NSMenuItem *preferencesMenuItem = [[[NSMenuItem alloc] initWithTitle:@"Preferences" action:@selector(showPreferences:) keyEquivalent:@""] autorelease];
	[preferencesMenuItem setTarget:self];
	[myStatusItemMenu addItem:preferencesMenuItem];
	
	NSMenuItem *aboutMenuItem = [[[NSMenuItem alloc] initWithTitle:@"About" action:@selector(showAbout:) keyEquivalent:@""] autorelease];
	[aboutMenuItem setTarget:self];
	[myStatusItemMenu addItem:aboutMenuItem];
	
	NSMenuItem *quitMenuItem = [[[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(doQuit:) keyEquivalent:@""] autorelease];
	[quitMenuItem setTarget:self];
	[myStatusItemMenu addItem:quitMenuItem];
	
	[autoreleasePool drain];
	
	return myStatusItemMenu;
} // eof buildStatusItemMenu

-(void)refreshStatusItemMenu {
	[statusItem setMenu:[self statusItemMenu]];
	[self setLastMountedLocalPath:nil];
} // eof refreshStatusItemMenu

-(void)findSshfs {
	if (currentTask != nil) {
        [currentTask terminate];
		[currentTask release];
		currentTask = nil;
	} // eof if()
	
	currentTask = [[NSTask alloc] init];
	[currentTask setCurrentDirectoryPath:[@"~" stringByExpandingTildeInPath]];
	[currentTask setLaunchPath:@"/usr/bin/which"];
	
	NSMutableArray *args = [NSMutableArray array];
	[args addObject:@"sshfs"];
	[currentTask setArguments:args];
	
	NSPipe *standardOutput = [[[NSPipe alloc] init] autorelease];
	[currentTask setStandardOutput:standardOutput];
	
	[currentTask launch];
	if ([currentTask isRunning] == YES) {
		currentOperationType = BTHFindSsshfsOperationType;
		[self setIsWorking:YES];
	} // eof if()
} // eof findSshfs

-(void)checkATaskStatus:(NSNotification *)aNotification {
	if (currentOperationType == BTHFindSsshfsOperationType) {
		[self retrieveSshfsPathFromTask:[aNotification object]];
	} else if (currentOperationType == BTHMountShareOperationType) {
		if ([[aNotification object] terminationStatus] != 0) {
			NSError *error = [NSError errorWithDomain:@"SSHFSManagerError" code:-2 userInfo:[NSDictionary dictionaryWithObject:@"Could not mount the selected share." forKey:NSLocalizedDescriptionKey]];	
			[[NSApplication sharedApplication] presentError:error];
			[self setLastMountedLocalPath:nil];
		} else {
			[self refreshStatusItemMenu];
		} // eof if()
	} else if (currentOperationType == BTHUnmountShareOperationType) {
		if ([[aNotification object] terminationStatus] != 0) {
			NSError *error = [NSError errorWithDomain:@"SSHFSManagerError" code:-3 userInfo:[NSDictionary dictionaryWithObject:@"Could not unmount the selected share." forKey:NSLocalizedDescriptionKey]];	
			[[NSApplication sharedApplication] presentError:error];
			[self setLastUnmountedLocalPath:nil];
		} else {
			[self refreshStatusItemMenu];
		} // eof if()
	} // eof if()
	
	[currentTask release];
	currentTask = nil;
	currentOperationType = BTHNoopOperationType;
	[self setIsWorking:NO];
} // eof checkATaskStatus:

-(void)retrieveSshfsPathFromTask:(NSTask *)aTask {
	NSError *error = [NSError errorWithDomain:@"SSHFSManagerError" code:-1 userInfo:[NSDictionary dictionaryWithObject:@"Could not locate SSHFS binary." forKey:NSLocalizedDescriptionKey]];
	if ([aTask terminationStatus] != 0) {
		// Since NSTasks don't respect the user's environment (PATHs in this case)
		// I decided not to show the error about not findings SSHFS binary.
		/*NSLog(@"sshfsFinderTask terminationStatus = %d", [aTask terminationStatus]);
		[NSApp presentError:error];*/
	} else {
		NSPipe *taskPipe = [aTask standardOutput];
		NSFileHandle *taskPipeFileHandle = [taskPipe fileHandleForReading];
		NSData *taskData = [taskPipeFileHandle availableData];
		NSString *sshfsBinaryPath = [[[NSString alloc] initWithData:taskData encoding:NSUTF8StringEncoding] autorelease];
		
		if ((sshfsBinaryPath != nil) && ([sshfsBinaryPath isEqualToString:@""] == NO)) {
			NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
			[preferences setValue:[sshfsBinaryPath stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"sshfsPath"];
			[preferences synchronize];
		} else {
			// Way too annoying.
			//[NSApp presentError:error];
		} // eof if()
	} // eof if()
} // eof retrieveSshfsPathFromTask:

-(void)managedObjectContextDidSave:(NSNotification *)aNotification {
	[self refreshStatusItemMenu];
} // eof managedObjectContextDidSave:

-(void)autoUpdateChangedFrom:(id)oldValue to:(id)newValue {
	if ((CFBooleanRef)newValue == kCFBooleanTrue) {
		[self setUpAutoUpdateTimer];
	} else if (((CFBooleanRef)newValue == kCFBooleanFalse) && (autoUpdateTimer != nil)) {
		[autoUpdateTimer invalidate];
		[autoUpdateTimer release];
		autoUpdateTimer = nil;
	} // eof if()
} // eof autoUpdateChangedFrom:to:

-(void)autoUpdateIntervalChangedFrom:(NSNumber *)oldInterval to:(NSNumber *)newInterval {
	[self setUpAutoUpdateTimer];
} // eof autoUpdateIntervalChangedFrom:to:
	
-(void)setUpAutoUpdateTimer {
	if (autoUpdateTimer != nil) {
		[autoUpdateTimer invalidate];
		[autoUpdateTimer release];
		autoUpdateTimer = nil;
	} // eof if()
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	NSTimeInterval timerInterval = [preferences integerForKey:@"autoUpdateInterval"] * 60;
	NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:timerInterval];
	autoUpdateTimer = [[NSTimer alloc] initWithFireDate:startDate interval:timerInterval target:self selector:@selector(fireTimer:) userInfo:nil repeats:YES];
	NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
	[runLoop addTimer:autoUpdateTimer forMode:NSDefaultRunLoopMode];
} // eof autoUpdateTimer

-(void)fireTimer:(NSTimer *)aTimer {
	[self refreshStatusItemMenu];
} // eof testTimer

-(void)mountShareWithSettings:(NSDictionary *)shareSettings {
	NSString *remotePath = [shareSettings objectForKey:@"remotePath"];
	if (remotePath == nil) {
		remotePath = @"";
	} // eof if()
	
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	
	if (currentTask != nil) {
		[currentTask release];
		currentTask = nil;
	} // eof if()
	
	currentTask = [[NSTask alloc] init];
	[currentTask setCurrentDirectoryPath:[@"~" stringByExpandingTildeInPath]];
	[currentTask setLaunchPath:[preferences valueForKey:@"sshfsPath"]];
	
	NSMutableArray *args = [NSMutableArray array];
	[args addObject:@"-p"];
	[args addObject:[NSString stringWithFormat:@"%d", [[shareSettings objectForKey:@"port"] intValue]]];
	[args addObject:[NSString stringWithFormat:@"%@@%@:%@",
					 [shareSettings objectForKey:@"login"],
					 [shareSettings objectForKey:@"host"],
					 remotePath]];
	[args addObject:[NSString stringWithFormat:@"%@", [shareSettings objectForKey:@"localPath"]]];
	[args addObject:[NSString stringWithFormat:@"-o%@,volname=%@",
					 [shareSettings objectForKey:@"options"],
					 [shareSettings objectForKey:@"volumeName"]]];
	
	[currentTask setArguments:args];
	
	[currentTask launch];
	
	if ([currentTask isRunning] == YES) {
		currentOperationType = BTHMountShareOperationType;
		[self setIsWorking:YES];
		[self setLastMountedLocalPath:[shareSettings objectForKey:@"localPath"]];
	} // eof if()
} // eof mountShareWithSetting:

-(void)unmountShareAtPath:(NSString *)shareLocalPath {
	if (currentTask != nil) {
		[currentTask release];
		currentTask = nil;
	} // eof if()
	
	currentTask = [[NSTask alloc] init];
	[currentTask setLaunchPath:@"/sbin/umount"];
	[currentTask setArguments:[NSArray arrayWithObject:shareLocalPath]];
	
	[currentTask launch];
	
	if ([currentTask isRunning] == YES) {
		currentOperationType = BTHUnmountShareOperationType;
		[self setLastUnmountedLocalPath:shareLocalPath];
		[self setIsWorking:YES];
	} // eof if()
} // eof unmountShareAtPath:

-(IBAction)doMountShare:(id)sender {
	NSDictionary *itemData = [sender itemData];
	if ([sender state] == NSOffState) {
		if (itemData != nil) {
			[self mountShareWithSettings:itemData];
		} // eof if()
	} else {
		NSString *localPath = [itemData objectForKey:@"localPath"];
		if (localPath != nil) {
			[self unmountShareAtPath:localPath];
		} // eof if()
	} // eof if()
} // eof doMountShare:

-(IBAction)doBrowseLocalPath:(id)sender {
	NSOpenPanel *localPathPanel = [NSOpenPanel openPanel];
	[localPathPanel setCanChooseFiles:NO];
	[localPathPanel setCanChooseDirectories:YES];
	[localPathPanel setAllowsMultipleSelection:NO];
	
	[localPathPanel beginSheetForDirectory:[@"~" stringByExpandingTildeInPath] file:@"" modalForWindow:preferencesWindow modalDelegate:self didEndSelector:@selector(localPathBrowseSheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
} // eof doBrowseLocalPath:

-(IBAction)doAddShare:(id)sender {
	[sharesController add:sender];
	[[shareNameField window] performSelector:@selector(makeFirstResponder:) withObject:shareNameField afterDelay:0.0];
} // eof doAddShare:

-(IBAction)showPreferences:(id)sender {
	[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
	[preferencesWindow makeKeyAndOrderFront:sender];
} // eof showPreferences:

-(IBAction)showAbout:(id)sender {
	[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
	[[NSApplication sharedApplication] orderFrontStandardAboutPanel:sender];
} // eof showAbout:

-(IBAction)doQuit:(id)sender {
	[[NSApplication sharedApplication] terminate:sender];
} // eof doQuit:
@end
