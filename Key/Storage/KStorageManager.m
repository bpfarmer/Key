//
//  KStorageManager.m
//  Key
//
//  Created by Brendan Farmer on 1/26/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KStorageManager.h"
#import "KAccountManager.h"
#import <YapDatabase/YapDatabase.h>
#import <YapDatabase/YapDatabaseRelationship.h>
#import <SSKeychain/SSKeychain.h>
#import "NSData+Base64.h"
#import "KYapDatabaseView.h"
#import "KYapDatabaseSecondaryIndex.h"
#import "KUser.h"
#import "Util.h"

NSString *const KUIDatabaseConnectionDidUpdateNotification = @"KUIDatabaseConnectionDidUpdateNotification";

@interface KStorageManager ()

@property (nonatomic, retain) NSMutableDictionary *databases;

@end

@implementation KStorageManager

+ (instancetype)sharedManager {
    static KStorageManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
        //[sharedMyManager protectDatabaseFile];
    });
    return sharedMyManager;
}

- (instancetype)init {
    self = [super init];
    
    return self;
}

- (NSData *)databasePassword {
    NSString *keychainDBPassKey = [NSString stringWithFormat:@"%@_%@", keychainDBPassAccount, [KAccountManager sharedManager].user.username];
    NSString *dbPassword = [SSKeychain passwordForService:keychainService account:keychainDBPassKey];
    
    if (!dbPassword) {
        dbPassword = [[Util generateRandomData:32] base64EncodedString];
        [SSKeychain setPassword:dbPassword forService:keychainService account:keychainDBPassKey];
    }
    return [dbPassword dataUsingEncoding:NSUTF8StringEncoding];
}

@end
