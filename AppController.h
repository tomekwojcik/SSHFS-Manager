//
//  AppController.h
//  SSHFS Manager
//
//  Created by Tomek Wójcik on 7/15/10.
//  Copyright 2010 Tomek Wójcik. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SSHFS_Manager_AppDelegate.h"

@interface AppController : NSObject {
	IBOutlet NSMenu *statusItemMenu;
	IBOutlet NSWindow *preferencesWindow;
	IBOutlet NSDrawer *shareDrawer;
	IBOutlet NSArrayController *sharesController;
	IBOutlet NSTextField *shareNameField;
	IBOutlet SSHFS_Manager_AppDelegate *appDelegate;
	
	NSString *currentTab;
	BOOL hasSshfs;
	BOOL isWorking;
	
	NSStatusItem *statusItem;
	NSImage *statusItemImage;
	
	int sshfsFinderPID;
	int shareMounterPID;
	NSString *lastMountedLocalPath;
}

@property (retain) NSString *currentTab;
@property BOOL hasSshfs;
@property BOOL isWorking;
@property (retain) NSString *lastMountedLocalPath;

-(void)tabChangedFrom:(NSString *)oldTab to:(NSString *)newTab;
-(void)sharesSelectionChangedFrom:(id)oldIndex to:(id)newIndex;
-(void)localPathBrowseSheetDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode  contextInfo:(void *)contextInfo;
-(NSMenu *)statusItemMenu;
-(void)refreshStatusItemMenu;
-(void)checkATaskStatus:(NSNotification *)aNotification;
-(void)findSshfs;
-(void)retrieveSshfsPathFromTask:(NSTask *)aTask;
-(void)sshfsPathChangedFrom:(NSString *)oldPath to:(NSString *)newPath;
-(void)managedObjectContextDidSave:(NSNotification *)aNotification;

-(IBAction)doMountShare:(id)sender;
-(IBAction)doBrowseLocalPath:(id)sender;
-(IBAction)doAddShare:(id)sender;
-(IBAction)showPreferences:(id)sender;
-(IBAction)showAbout:(id)sender;
-(IBAction)doQuit:(id)sender;
@end
