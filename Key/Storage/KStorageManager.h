//
//  KStorageManager.h
//  Key
//
//  Created by Brendan Farmer on 1/26/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FMDB/FMDB.h>

@class TOCFuture;

extern NSString *const KUIDatabaseConnectionDidUpdateNotification;

static NSString *keychainService          = @"KKeyChainService";
static NSString *keychainDBPassAccount    = @"KDatabasePass";

@interface KStorageManager : NSObject

@property (nonatomic, strong) FMDatabase *database;

+ (instancetype)sharedManager;
- (void)setDatabaseWithName:(NSString *)databaseName;
- (TOCFuture *)queryUpdate:(NSString *)sql parameters:(NSDictionary *)parameters;
- (TOCFuture *)querySelect:(NSString *)sql parameters:(NSDictionary *)parameters;

@end