//
//  KPost.m
//  Key
//
//  Created by Brendan Farmer on 4/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KPost.h"
#import "KUser.h"
#import "KStorageManager.h"

@implementation KPost

- (KUser *)author {
    return [[KStorageManager sharedManager] objectForKey:self.authorId inCollection:[KUser collection]];
}

@end
