//
//  KDatabaseObject.h
//  Key
//
//  Created by Brendan Farmer on 7/6/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMResultSet;
@class TOCFuture;

@interface KDatabaseObject : NSObject

@property (nonatomic, readwrite) NSString *uniqueId;

+ (NSString *)tableName;
- (void)save;
- (void)remove;
+ (void)createTable;
+ (void)dropTable;
- (instancetype)initWithUniqueId:(NSString *)uniqueId;
- (instancetype)initWithResultSetRow:(NSDictionary *)row;
+ (TOCFuture *)all;

@end
