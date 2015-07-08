//
//  KDatabaseObject.h
//  Key
//
//  Created by Brendan Farmer on 7/6/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

@class FMResultSet;
@class TOCFuture;

@interface KDatabaseObject : MTLModel

@property (nonatomic, copy) NSString *uniqueId;

+ (NSString *)tableName;
- (void)save;
- (void)remove;
+ (void)createTable;
+ (void)dropTable;
- (instancetype)initWithUniqueId:(NSString *)uniqueId;
- (instancetype)initWithResultSet:(FMResultSet *)resultSet;
+ (instancetype)findByUniqueId:(NSString *)uniqueId;
+ (instancetype)findByDictionary:(NSDictionary *)dictionary;
+ (NSArray *)findAllByDictionary:(NSDictionary *)dictionary;
+ (FMResultSet *)all;
+ (NSArray *)storedPropertyList;
+ (NSArray *)unsavedPropertyList;
- (NSDictionary *)instanceMapping;
+ (NSDictionary *)propertyMapping;



@end
