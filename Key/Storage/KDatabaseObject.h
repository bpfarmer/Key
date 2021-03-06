//
//  KDatabaseObject.h
//  Key
//
//  Created by Brendan Farmer on 7/6/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>
#import "NSObject+Properties.h"

@class FMResultSet;
@class TOCFuture;

@interface KDatabaseObject : MTLModel

@property (nonatomic) NSString *uniqueId;

+ (NSString *)tableName;
- (void)save;
- (void)remove;
- (void)addRecipientIds:(NSArray *)recipientIds;
- (NSArray *)recipientIds;
- (void)sendToRecipientIds:(NSArray *)recipientIds withAttachableObjects:(NSArray *)attachableObjects;
- (void)sendWithAttachableObjects:(NSArray *)attachableObjects;
+ (void)createTable;
+ (void)dropTable;
- (instancetype)initWithUniqueId:(NSString *)uniqueId;
- (instancetype)initWithResultSetRow:(NSDictionary *)resultSetRow;
+ (instancetype)findById:(id)uniqueId;
+ (instancetype)findByDictionary:(NSDictionary *)dictionary;
+ (NSArray *)findAllByDictionary:(NSDictionary *)dictionary;
+ (NSArray *)findAllByDictionary:(NSDictionary *)dictionary orderBy:(NSString *)orderProperty descending:(BOOL)descending;
+ (NSArray *)findAllByIds:(NSArray *)ids;
+ (NSArray *)findAllWhere:(NSString *)where parameters:(NSDictionary *)parameters;
+ (NSArray *)all;
+ (NSArray *)storedPropertyList;
+ (NSArray *)unsavedPropertyList;
- (NSDictionary *)instanceMapping;
+ (NSDictionary *)propertyToColumnMapping;
+ (NSDictionary *)columnToPropertyMapping;
+ (NSDictionary *)propertyTypeToColumnTypeMapping;
+ (NSString *)notificationChannel;
+ (NSString *)generateUniqueId;
+ (NSString *)generateUniqueIdWithClass;
+ (BOOL)compareProperty:(NSString *)name object1:(KDatabaseObject *)object1 object2:(KDatabaseObject *)object2;

@end
