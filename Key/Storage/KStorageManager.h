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

static NSString *keychainService          = @"KKeyChainService";
static NSString *keychainDBPassAccount    = @"KDatabasePass";

typedef void (^KDatabaseUpdateBlock)(FMDatabase *database);
typedef FMResultSet* (^KDatabaseSelectBlock)(FMDatabase *database);
typedef NSUInteger (^KDatabaseCountBlock)(FMDatabase *database);

@interface KStorageManager : NSObject

@property (nonatomic) FMDatabase *database;
@property (nonatomic) FMDatabaseQueue *queue;

+ (instancetype)sharedManager;
- (void)setDatabaseWithName:(NSString *)databaseName;
- (void)queryUpdate:(KDatabaseUpdateBlock)databaseBlock;
- (FMResultSet *)querySelect:(KDatabaseSelectBlock)databaseBlock;
- (NSUInteger)queryCount:(KDatabaseCountBlock)databaseBlock;

@end