//
//  SSHFS_Manager_AppDelegate.h
//  SSHFS Manager
//
//  Created by Tomek Wójcik on 7/15/10.
//  Copyright Tomek Wójcik 2010 . All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SSHFS_Manager_AppDelegate : NSObject 
{
    IBOutlet NSWindow *window;
    
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *)managedObjectContext;

- (IBAction)saveAction:sender;

@end
