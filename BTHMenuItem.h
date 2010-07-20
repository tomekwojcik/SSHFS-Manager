//
//  BTHMenuItem.h
//  SSHFS Manager
//
//  Created by Tomek Wójcik on 7/16/10.
//  Copyright 2010 Tomek Wójcik. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BTHMenuItem : NSMenuItem {
	NSDictionary *itemData;
}

-(NSDictionary *)itemData;
-(void)setItemData:(NSDictionary *)newItemData;
@end
