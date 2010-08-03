/**
 *  AppController.h
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

#import <Cocoa/Cocoa.h>
#import "SSHFS_Manager_AppDelegate.h"

typedef enum {
	BTHNoopOperationType = 0,
	BTHFindSsshfsOperationType = 1,
	BTHMountShareOperationType = 2,
	BTHUnmountShareOperationType = 3
} BTHOperationType;

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
	
	BTHOperationType currentOperationType;
	NSString *lastMountedLocalPath;
	NSString *lastUnmountedLocalPath;
	NSTimer *autoUpdateTimer;
	NSTask *currentTask;
}

@property (retain) NSString *currentTab;
@property BOOL hasSshfs;
@property BOOL isWorking;
@property (retain) NSString *lastMountedLocalPath;
@property (retain) NSString *lastUnmountedLocalPath;

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
-(void)autoUpdateChangedFrom:(id)oldValue to:(id)newValue;
-(void)autoUpdateIntervalChangedFrom:(NSNumber *)oldInterval to:(NSNumber *)newInterval;
-(void)setUpAutoUpdateTimer;
-(void)fireTimer:(NSTimer *)aTimer;
-(void)mountShareWithSettings:(NSDictionary *)shareSettings;
-(void)unmountShareAtPath:(NSString *)shareLocalPath;

-(IBAction)doMountShare:(id)sender;
-(IBAction)doBrowseLocalPath:(id)sender;
-(IBAction)doAddShare:(id)sender;
-(IBAction)showPreferences:(id)sender;
-(IBAction)showAbout:(id)sender;
-(IBAction)doQuit:(id)sender;
@end
