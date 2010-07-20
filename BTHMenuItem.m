//
//  BTHMenuItem.m
//  SSHFS Manager
//
//  Created by Tomek Wójcik on 7/16/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BTHMenuItem.h"


@implementation BTHMenuItem
-(id)initWithTitle:(NSString *)itemName action:(SEL)anAction keyEquivalent:(NSString *)charCode {
	if (self = [super initWithTitle:itemName action:anAction keyEquivalent:charCode]) {
		itemData = nil;
	} // eof if()
	
	return self;
} // eof if()

-(void)dealloc {
	[itemData release]; itemData = nil;
	
	[super dealloc];
} // eof dealloc

-(NSDictionary *)itemData {
	return itemData;
} // eof itemData

-(void)setItemData:(NSDictionary *)newItemData {
	if (newItemData != itemData) {
		[itemData release];
		itemData = [[NSDictionary alloc] initWithDictionary:newItemData];
	} // eof if()
} // eof setItemData:
@end
