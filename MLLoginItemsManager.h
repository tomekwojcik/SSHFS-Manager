//
//  MLLoginItemsManager.h
//
//  Created by Mateusz Lenik on 10-05-01.
//  Copyright 2010 MLen. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MLLoginItemsManager : NSObject {
    LSSharedFileListRef list;
}
@property (assign) BOOL loginItems;
@end
