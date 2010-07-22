//
//  MLLoginItemsManager.m
//
//  Created by Mateusz Lenik on 10-05-01.
//  Copyright 2010 MLen. All rights reserved.
//

#import "MLLoginItemsManager.h"

@interface MLLoginItemsManager ()
static void loginItemsChanged(LSSharedFileListRef l, void *self);
@end

@implementation MLLoginItemsManager

- (id)init {
    if (self = [super init]) {
        list = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
        NSAssert(list != nil, @"File list creation failed...");

        LSSharedFileListAddObserver(list,
                                    [[NSRunLoop mainRunLoop] getCFRunLoop],
                                    kCFRunLoopDefaultMode,
                                    loginItemsChanged,
                                    self);
    }
    
    return self;
}

- (void)dealloc {
    LSSharedFileListRemoveObserver(list,
                                   [[NSRunLoop mainRunLoop] getCFRunLoop],
                                   kCFRunLoopDefaultMode,
                                   loginItemsChanged,
                                   self);
    CFRelease(list);
    
    [super dealloc];
}

- (void)setLoginItems:(BOOL)v {
    
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];

    NSArray *array = (NSArray *)LSSharedFileListCopySnapshot(list, NULL);
    
    LSSharedFileListItemRef foundItem = NULL;
    
    for (id item in array) {
        NSURL *appUrl;
        LSSharedFileListItemResolve((LSSharedFileListItemRef)item,
                                    kLSSharedFileListNoUserInteraction |
                                    kLSSharedFileListDoNotMountVolumes,
                                    (CFURLRef *)&appUrl,
                                    NULL);
        
        if ([url isEqualTo:appUrl]) {
            foundItem = (LSSharedFileListItemRef)item;
            break;
        }
        [appUrl release];
    }
    
    if (v && nil == foundItem) {
        NSString *name = [[NSFileManager defaultManager] displayNameAtPath:[url path]];
        
        NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:[url path]];
        
        CFRelease(LSSharedFileListInsertItemURL(list,
                                      kLSSharedFileListItemLast,
                                      (CFStringRef)name,
                                      (IconRef)icon,
                                      (CFURLRef)url,
                                      NULL,
                                      NULL));
    }
    else if (!v && nil != foundItem) {
        LSSharedFileListItemRemove(list, foundItem);
    }
    
    
    [array release];
}

- (BOOL)loginItems {
    BOOL result = NO;
    
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
    
    NSArray *array = (NSArray *)LSSharedFileListCopySnapshot(list, NULL);
    
    for (id item in array) {
        NSURL *appUrl;
        LSSharedFileListItemResolve((LSSharedFileListItemRef)item, 
                                    kLSSharedFileListNoUserInteraction |
                                    kLSSharedFileListDoNotMountVolumes, 
                                    (CFURLRef *)&appUrl,
                                    NULL);
        
        if ([url isEqualTo:appUrl]) {
            result = YES;
            break;
        }
        
        [appUrl release];
    }
    
    [array release];
    
    return result;
}

static void loginItemsChanged(LSSharedFileListRef l, void *self) {
    if (l == ((MLLoginItemsManager *)self)->list) {
        [(MLLoginItemsManager *)self willChangeValueForKey:@"loginItems"]; // ugly hack to update the interface
        [(MLLoginItemsManager *)self didChangeValueForKey:@"loginItems"];
    }
}
@end
