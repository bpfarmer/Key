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
#import "PreKey.h"
#import "PreKeyExchange.h"
#import "RootChain.h"

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
    [PreKey createTable];
    [PreKeyExchange createTable];
    [RootChain createTable];
}

+ (void)dropTables {
    [KUser dropTable];
    [IdentityKey dropTable];
    [KMessage dropTable];
    [KThread dropTable];
    [KGroup dropTable];
    [Session dropTable];
    [SessionState dropTable];
    [RootChain dropTable];
    [KOutgoingObject dropTable];
    [KPhoto dropTable];
    [KLocation dropTable];
    [PreKeyExchange dropTable];
    [PreKey dropTable];
    [RootChain dropTable];
}


@end
