//
//  KStorageSchema.m
//  Key
//
//  Created by Brendan Farmer on 7/9/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KStorageSchema.h"
#import "KUser.h"
#import "IdentityKey.h"
#import "KMessage.h"
#import "KThread.h"
#import "KGroup.h"
#import "Session.h"
#import "RootChain.h"
#import "SessionState.h"
#import "KOutgoingObject.h"
#import "KPhoto.h"
#import "KLocation.h"

@implementation KStorageSchema

+ (void)createTables {
    [KUser createTable];
    [IdentityKey createTable];
    [KMessage createTable];
    [KThread createTable];
    [KGroup createTable];
    [Session createTable];
    [SessionState createTable];
    [RootChain createTable];
    [KOutgoingObject createTable];
    [KPhoto createTable];
    [KLocation createTable];
}

@end
