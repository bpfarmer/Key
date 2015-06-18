//
//  KYapDatabaseView.m
//  Key
//
//  Created by Brendan Farmer on 2/5/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KYapDatabaseView.h"
#import "KThread.h"
#import "KStorageManager.h"
#import "KUser.h"
#import "KMessage.h"
#import "KAccountManager.h"
#import "KPost.h"

NSString *KInboxGroup                       = @"KInboxGroup";
NSString *KThreadGroup                      = @"KThreadGroup";
NSString *KContactGroup                     = @"KContactGroup";
NSString *KPostGroup                        = @"KPostGroup";
NSString *KThreadDatabaseViewName  = @"KThreadDatabaseViewExtension";
NSString *KMessageDatabaseViewName = @"KMessageDatabaseViewExtension";
NSString *KContactDatabaseViewName = @"KContactDatabaseViewExtension";
NSString *KPostDatabaseViewName    = @"KPostDatabaseViewExtension";

@implementation KYapDatabaseView

+ (BOOL) registerThreadDatabaseView {
    if ([[[KStorageManager sharedManager] database] registeredExtension:KThreadDatabaseViewName]) {
        return YES;
    }
    YapDatabaseViewGrouping *viewGrouping = [YapDatabaseViewGrouping withObjectBlock:^NSString *(NSString *collection, NSString *key, id object) {
        if ([object isKindOfClass:[KThread class]]){
            return KInboxGroup;
        }
        return nil;
    }];
    
    YapDatabaseViewSorting *viewSorting = [self threadSorting];
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:[NSSet setWithObject:[KThread collection]]];
    
    YapDatabaseView *databaseView = [[YapDatabaseView alloc] initWithGrouping:viewGrouping
                                                                      sorting:viewSorting
                                                                   versionTag:@"1"
                                                                      options:options];
    
    return [[[KStorageManager sharedManager] database] registerExtension:databaseView withName:KThreadDatabaseViewName];
}

+ (BOOL) registerMessageDatabaseView {
    if ([[[KStorageManager sharedManager] database] registeredExtension:KMessageDatabaseViewName]) {
        return YES;
    }
    
    YapDatabaseViewGrouping *viewGrouping = [YapDatabaseViewGrouping withObjectBlock:^NSString *(NSString *collection, NSString *key, id object) {
        if ([object isKindOfClass:[KMessage class]]){
            KMessage *message = (KMessage *)object;
            if(message.threadId) {
                return ((KMessage *) object).threadId;
            }
        }
        return nil;
    }];
    
    YapDatabaseViewSorting *viewSorting = [self messageSorting];
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:[NSSet setWithObject:[KMessage collection]]];
    
    YapDatabaseView *view = [[YapDatabaseView alloc] initWithGrouping:viewGrouping
                                                              sorting:viewSorting
                                                           versionTag:@"1"
                                                              options:options];
    
    return [[[KStorageManager sharedManager] database] registerExtension:view withName:KMessageDatabaseViewName];
}

+ (BOOL)registerContactDatabaseView {
    if([[[KStorageManager sharedManager] database] registeredExtension:KContactDatabaseViewName]) {
        return YES;
    }
    YapDatabaseViewGrouping *viewGrouping = [YapDatabaseViewGrouping withObjectBlock:^NSString *(NSString *collection, NSString *key, id object) {
        if([object isKindOfClass:[KUser class]]){
            KUser *user = (KUser *)object;
            if(![user.username isEqual:[KAccountManager sharedManager].user.username])
                return KContactGroup;
        }
        return nil;
    }];
    YapDatabaseViewSorting *viewSorting = [self userSorting];
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:[NSSet setWithObject:[KUser collection]]];
    
    YapDatabaseView *databaseView = [[YapDatabaseView alloc] initWithGrouping:viewGrouping
                                                                      sorting:viewSorting
                                                                   versionTag:@"1"
                                                                      options:options];
    
    return [[[KStorageManager sharedManager] database] registerExtension:databaseView withName:KContactDatabaseViewName];

}

+ (BOOL)registerPostDatabaseView {
    if([[[KStorageManager sharedManager] database] registeredExtension:KPostDatabaseViewName]) {
        return YES;
    }
    YapDatabaseViewGrouping *viewGrouping = [YapDatabaseViewGrouping withObjectBlock:^NSString *(NSString *collection, NSString *key, id object) {
        if([object isKindOfClass:[KPost class]]) {
            return KPostGroup;
        }
        return nil;
    }];
    YapDatabaseViewSorting *viewSorting = [self postSorting];
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:[NSSet setWithObject:[KPost collection]]];
    
    YapDatabaseView *databaseView = [[YapDatabaseView alloc] initWithGrouping:viewGrouping
                                                                      sorting:viewSorting
                                                                   versionTag:@"1"
                                                                      options:options];
    return [[[KStorageManager sharedManager] database] registerExtension:databaseView withName:KPostDatabaseViewName];
}

+ (YapDatabaseViewSorting *)messageSorting {
    return [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(NSString *group, NSString *collection1, NSString *key1, id object1, NSString *collection2, NSString *key2, id object2) {
        /*if ([object1 isKindOfClass:[KMessage class]] && [object2 isKindOfClass:[KMessage class]]) {
            KMessage *message1 = (KMessage *) object1;
            KMessage *message2 = (KMessage *) object2;
            
            return [message1.createdAt compare:message2.createdAt];
        }*/
        return NSOrderedSame;
    }];
}

+ (YapDatabaseViewSorting *)threadSorting {
    return [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(NSString *group, NSString *collection1, NSString *key1, id object1, NSString *collection2, NSString *key2, id object2) {
        if([group isEqualToString:KInboxGroup]) {
            if([object1 isKindOfClass:[KThread class]] && [object2 isKindOfClass:[KThread class]]){
                KThread *thread1 = (KThread *)object1;
                KThread *thread2 = (KThread *)object2;
                
                return [thread2.latestMessage.createdAt compare:thread1.latestMessage.createdAt];
            }
        }
        return NSOrderedSame;
    }];
}

+ (YapDatabaseViewSorting *)userSorting {
    return [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(NSString *group, NSString *collection1, NSString *key1, id object1, NSString *collection2, NSString *key2, id object2) {
        if([group isEqualToString:KContactGroup]) {
            if([object1 isKindOfClass:[KUser class]] && [object2 isKindOfClass:[KUser class]]) {
                KUser *user1 = (KUser *)object1;
                KUser *user2 = (KUser *)object2;
                
                return [[user1 displayName] compare:[user2 displayName]];
            }
        }
        return NSOrderedSame;
    }];
}

+ (YapDatabaseViewSorting *)postSorting {
    return [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(NSString *group, NSString *collection1, NSString *key1, id object1, NSString *collection2, NSString *key2, id object2) {
        if([group isEqualToString:KPostGroup]) {
            if([object1 isKindOfClass:[KPost class]] && [object2 isKindOfClass:[KPost class]]){
                KPost *post1 = (KPost *)object1;
                KPost *post2 = (KPost *)object2;
                
                return [post2.createdAt compare:post1.createdAt];
            }
        }
        return NSOrderedSame;
    }];
}

@end
