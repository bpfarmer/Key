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
#import "KOutgoingMessage.h"

NSString *KInboxGroup                       = @"KInboxGroup";
NSString *KThreadGroup                      = @"KThreadGroup";
NSString *KThreadDatabaseViewExtensionName  = @"KThreadDatabaseViewExtension";
NSString *KMessageDatabaseViewExtensionName = @"KMessageDatabaseViewExtensionName";

@implementation KYapDatabaseView

+ (BOOL) registerThreadDatabaseView {
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
    
    return [[[KStorageManager sharedManager] database] registerExtension:databaseView withName:KThreadDatabaseViewExtensionName];
}

+ (BOOL) registerMessageDatabaseView {
    if ([[KStorageManager sharedManager].database registeredExtension:KMessageDatabaseViewExtensionName]) {
        return YES;
    }
    
    YapDatabaseViewGrouping *viewGrouping = [YapDatabaseViewGrouping withObjectBlock:^NSString *(NSString *collection, NSString *key, id object) {
        if ([object isKindOfClass:[KMessage class]]){
            return ((KMessage *) object).threadId;
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
    
    return [[KStorageManager sharedManager].database registerExtension:view withName:KMessageDatabaseViewExtensionName];
}

+ (YapDatabaseViewSorting *) messageSorting {
    return [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(NSString *group, NSString *collection1, NSString *key1, id object1, NSString *collection2, NSString *key2, id object2) {
        /*if ([object1 isKindOfClass:[KMessage class]] && [object2 isKindOfClass:[KMessage class]]) {
            KMessage *message1 = (KMessage *) object1;
            KMessage *message2 = (KMessage *) object2;
            
            return [message1.createdAt compare:message2.createdAt];
        }*/
        return NSOrderedSame;
    }];
}

+ (YapDatabaseViewSorting*) threadSorting {
    return [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(NSString *group, NSString *collection1, NSString *key1, id object1, NSString *collection2, NSString *key2, id object2) {
        if ([group isEqualToString:KInboxGroup]) {
            if ([object1 isKindOfClass:[KThread class]] && [object2 isKindOfClass:[KThread class]]){
                KThread *thread1 = (KThread *)object1;
                KThread *thread2 = (KThread *)object2;
                
                return [thread2.lastMessageAt compare:thread1.lastMessageAt];
            }
        }
        return NSOrderedSame;
    }];
    
}

@end
