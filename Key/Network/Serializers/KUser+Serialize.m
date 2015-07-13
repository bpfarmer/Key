//
//  KUser+Serialize.m
//  Key
//
//  Created by Brendan Farmer on 3/14/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KUser+Serialize.h"
#import "IdentityKey.h"
#import "KStorageManager.h"
#import "CollapsingFutures.h"
#import <objc/runtime.h>

@implementation KUser(Serialize)

+ (NSArray *)unsavedPropertyList {
    NSMutableArray *unstoredProperties = [[NSMutableArray alloc] initWithArray:[super unsavedPropertyList]];
    [unstoredProperties addObject:@"identityKey"];
    return unstoredProperties;
}

@end
