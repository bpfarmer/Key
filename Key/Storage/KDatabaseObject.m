//
//  KDatabaseObject.m
//  Key
//
//  Created by Brendan Farmer on 7/6/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KDatabaseObject.h"
#import "KStorageManager.h"
#import <objc/runtime.h>

#define kMappingUniqueId @"uniqueId"
#define kMappingPrimaryKeyId @"primaryKeyId"
#define kColumnTypeBlob @"blob"

@implementation KDatabaseObject

+ (void)createTable {
    NSMutableArray *createdColumns = [[NSMutableArray alloc] init];
    [createdColumns addObject:@"unique_id text primary key not null"];
    NSMutableArray *propertyList = [[NSMutableArray alloc] initWithArray:[self storedPropertyList]];
    [propertyList removeObjectsInArray:@[@"uniqueId"]];
    for(NSString *property in propertyList) {
        [createdColumns addObject:[NSString stringWithFormat:@"%@ %@", [self propertyToColumnMapping][property], [self columnTypeForProperty:property]]];
    }
    NSString *createTableSQL = [NSString stringWithFormat:@"create table if not exists %@ (%@)", [self tableName], [createdColumns componentsJoinedByString:@", "]];

    [[KStorageManager sharedManager] queryUpdate:^(FMDatabase *database) {
        [database executeUpdate:createTableSQL];
    }];
}

+ (void)dropTable {
    NSString *dropTableSQL = [NSString stringWithFormat:@"drop table %@;", [self tableName]];
    [[KStorageManager sharedManager] queryUpdate:^(FMDatabase *database) {
        [database executeUpdate:dropTableSQL];
    }];
}

+ (NSString *)columnTypeForProperty:(NSString *)property {
    NSString *propertyType = [self typeOfPropertyNamed:property];
    NSString *columnType   = [self propertyTypeToColumnTypeMapping][propertyType];
    if(!columnType) columnType = kColumnTypeBlob;
    return columnType;
}

+(NSDictionary *)propertyTypeToColumnTypeMapping {
    return @{@"NSString" : @"text", @"bool" : @"integer", @"float" : @"real", @"int" : @"integer", @"NSInteger" : @"integer", @"NSNumber" : @"integer", @"NSUInteger" : @"integer"};
}

+ (NSArray *)storedPropertyList {
    NSMutableArray *propertyNames = [[NSMutableArray alloc] initWithArray:[self propertyNames]];
    [propertyNames addObject:kMappingUniqueId];
    [propertyNames removeObjectsInArray:@[@"hash", @"superclass", @"description", @"debugDescription"]];
    [propertyNames removeObjectsInArray:[[self class] unsavedPropertyList]];
    return propertyNames;
}

+ (NSArray *)unsavedPropertyList {
    return @[];
}

+ (NSDictionary *)columnToPropertyMapping {
    NSMutableDictionary *mappingDictionary = [[NSMutableDictionary alloc] init];
    NSArray *storedProperties = [[self class] storedPropertyList];
    for(NSString *storedProperty in storedProperties) {
        [mappingDictionary setObject:storedProperty forKey:[self columnNameFromProperty:storedProperty]];
    }
    return [NSDictionary dictionaryWithDictionary:mappingDictionary];
}

+ (NSDictionary *)propertyToColumnMapping {
    NSMutableDictionary *mappingDictionary = [[NSMutableDictionary alloc] init];
    NSArray *storedProperties = [[self class] storedPropertyList];
    for(NSString *storedProperty in storedProperties) {
        [mappingDictionary setObject:[self columnNameFromProperty:storedProperty] forKey:storedProperty];
    }
    return [NSDictionary dictionaryWithDictionary:mappingDictionary];
}

+ (NSString *)columnNameFromProperty:(NSString *)name {
    NSMutableString *output = [NSMutableString string];
    NSCharacterSet *uppercase = [NSCharacterSet uppercaseLetterCharacterSet];
    for (NSInteger idx = 0; idx < [name length]; idx += 1) {
        unichar c = [name characterAtIndex:idx];
        if ([uppercase characterIsMember:c]) {
            if(idx == 0) [output appendFormat:@"%@", [[NSString stringWithCharacters:&c length:1] lowercaseString]];
            else [output appendFormat:@"_%@", [[NSString stringWithCharacters:&c length:1] lowercaseString]];
        } else {
            [output appendFormat:@"%C", c];
        }
    }
    if([output isEqualToString:@"index"]) return @"kIndex";
    return output;
}

- (void)remove {
    NSString *deleteSQL = [NSString stringWithFormat:@"delete from %@ where unique_id=:unique_id", [[self class] tableName]];
    NSDictionary *parameterDictionary = @{@"unique_id" : self.uniqueId};
    [[KStorageManager sharedManager] queryUpdate:^(FMDatabase *database) {
        [database executeUpdate:deleteSQL withParameterDictionary:parameterDictionary];
    }];
}

- (void)save {
    if(!self.uniqueId) self.uniqueId = [self.class generateUniqueId];
    NSString *columnKeys = [[self instanceMapping].allKeys componentsJoinedByString:@", "];
    NSString *valueKeys   = [@":" stringByAppendingString:[[self instanceMapping].allKeys componentsJoinedByString:@", :"]];
    NSString *insertOrReplaceSQL = [NSString stringWithFormat:@"insert or replace into %@ (%@) values(%@)", [self.class tableName], columnKeys, valueKeys];
    //NSLog(@"SAVING WITH SQL: %@ AND PARAMETERS: %@", insertOrReplaceSQL, [self instanceMapping]);
    [[KStorageManager sharedManager] queryUpdate:^(FMDatabase *database) {
        [database executeUpdate:insertOrReplaceSQL withParameterDictionary:[self instanceMapping]];
    }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:[[self class] notificationChannel] object:self userInfo:nil];
}

+ (NSString *)notificationChannel {
    return [NSString stringWithFormat:@"%@UpdateChannel", [self tableName]];
}

+ (NSArray *)all {
    NSString *findAllSQL = [NSString stringWithFormat:@"select * from %@", [self.class tableName]];
    FMResultSet *resultSet = [[KStorageManager sharedManager] querySelect:^FMResultSet *(FMDatabase *database) {
        return [database executeQuery:findAllSQL];
    }];
    NSMutableArray *objects = [[NSMutableArray alloc] init];
    while(resultSet.next) [objects addObject:[[self alloc] initWithResultSetRow:resultSet.resultDictionary]];
    [resultSet close];
    return [objects copy];
}

+ (instancetype)findById:(NSString *)uniqueId {
    if(!uniqueId) return nil;
    NSDictionary *parameterDictionary = @{@"unique_id" : uniqueId};
    NSString *findByUniqueIdSQL = [NSString stringWithFormat:@"select * from %@ where unique_id=:unique_id", [[self class] tableName]];
    //NSLog(@"FINDING WITH SQL: %@ AND PARAMETERS: %@",findByUniqueIdSQL, parameterDictionary);
    FMResultSet *result = [[KStorageManager sharedManager] querySelect:^FMResultSet *(FMDatabase *database) {
        return [database executeQuery:findByUniqueIdSQL withParameterDictionary:parameterDictionary];
    }];
    if(result.next) {
        KDatabaseObject *object = [[self alloc] initWithResultSetRow:result.resultDictionary];
        [result close];
        return object;

    }
    return nil;
}

+ (instancetype)findByDictionary:(NSDictionary *)dictionary {
    NSMutableArray *conditions = [[NSMutableArray alloc] init];
    for(NSString *key in [dictionary allKeys]) {
        if(![[self storedPropertyList] containsObject:key]) return nil;
        [conditions addObject:[NSString stringWithFormat:@"%@ = :%@", [self propertyToColumnMapping][key], [self propertyToColumnMapping][key]]];
    }
    NSString *selectSQL = [NSString stringWithFormat:@"select * from %@ where %@", [self tableName], [conditions componentsJoinedByString:@" AND "]];

    NSMutableDictionary *parameterDictionary = [[NSMutableDictionary alloc] init];
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [parameterDictionary setObject:obj forKey:[self columnNameFromProperty:key]];
    }];
    
    //NSLog(@"FINDING WITH SQL: %@ AND PARAMETERS: %@", selectSQL, parameterDictionary);
    
    FMResultSet *resultSet = [[KStorageManager sharedManager] querySelect:^FMResultSet *(FMDatabase *database) {
        return [database executeQuery:selectSQL withParameterDictionary:[parameterDictionary copy]];
    }];
    
    if(resultSet.next) {
        KDatabaseObject *object = [[self alloc] initWithResultSetRow:resultSet.resultDictionary];
        [resultSet close];
        return object;
    }else {
        return nil;
    }
}

- (instancetype)initWithUniqueId:(NSString *)uniqueId {
    self = [super init];
    if(self) _uniqueId = uniqueId;
    return self;
}

- (NSDictionary *)instanceMapping {
    __block NSMutableDictionary *instanceMap = [[NSMutableDictionary alloc] init];
    NSDictionary *mappingDictionary = [[self class] columnToPropertyMapping];
    [mappingDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if([self valueForKey:(NSString *)obj]) {
            if([[[self class] columnTypeForProperty:obj] isEqualToString:kColumnTypeBlob] && ![[self valueForKey:obj] isKindOfClass:[NSData class]])
                [instanceMap setObject:[NSKeyedArchiver archivedDataWithRootObject:[self valueForKey:obj]] forKey:key];
            else [instanceMap setObject:[self valueForKey:obj] forKey:key];
        }
    }];
    return instanceMap;
}

- (instancetype)initWithResultSetRow:(NSDictionary *)resultSetRow {
    self = [super init];
    [[[self class] columnToPropertyMapping] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if(![resultSetRow[key] isKindOfClass:[NSNull class]]) {
            if([[[self class] columnTypeForProperty:obj] isEqualToString:kColumnTypeBlob] && ![[[self class] typeOfPropertyNamed:obj] isEqualToString:@"NSData"])
                [self setValue:[NSKeyedUnarchiver unarchiveObjectWithData:resultSetRow[key]] forKey:obj];
            else [self setValue:resultSetRow[key] forKey:obj];
        }
    }];
    return self;
}

+ (NSString *)tableName {
    return [self columnNameFromProperty:NSStringFromClass([self class])];
}

+ (NSString *)generateUniqueId {
    return [[NSUUID UUID] UUIDString];
}

@end
