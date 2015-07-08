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

@implementation KDatabaseObject

+ (void)createTable {
    NSMutableArray *createdColumns = [[NSMutableArray alloc] init];
    if([self hasUniqueId]) [createdColumns addObject:@"unique_id text primary key not null"];
    else [createdColumns addObject:@"primary_key_id integer primary key autoincrement not null"];
    NSMutableArray *propertyList = [[NSMutableArray alloc] initWithArray:[self storedPropertyList]];
    [propertyList removeObjectsInArray:@[@"uniqueId", @"primary_key_id"]];
    for(NSString *property in propertyList) {
        NSString *propertyType = [self typeOfPropertyNamed:property];
        NSString *columnType   = [self propertyTypeToColumnTypeMapping][propertyType];
        if(!columnType) columnType = @"blob";
        [createdColumns addObject:[NSString stringWithFormat:@"%@ %@", [self propertyToColumnMapping][property], columnType]];
    }
    NSString *createTableSQL = [NSString stringWithFormat:@"create table %@ (%@)", [self tableName], [createdColumns componentsJoinedByString:@", "]];
    [[KStorageManager sharedManager] queryUpdate:^(FMDatabase *database) {
        [database executeUpdate:createTableSQL];
    }];
}

+ (void)dropTable {
    NSString *dropTableSQL = [NSString stringWithFormat:@"drop table %@;", [self class]];
    [[KStorageManager sharedManager] queryUpdate:^(FMDatabase *database) {
        [database executeUpdate:dropTableSQL];
    }];
}

+(NSDictionary *)propertyTypeToColumnTypeMapping {
    return @{@"NSString" : @"text", @"bool" : @"integer", @"float" : @"real", @"int" : @"integer"};
}

+ (NSArray *)storedPropertyList {
    NSMutableArray *propertyNames = [[NSMutableArray alloc] initWithArray:[self propertyNames]];
    if([self hasUniqueId]) [propertyNames addObject:kMappingUniqueId];
    else [propertyNames addObject:kMappingPrimaryKeyId];
    [propertyNames removeObjectsInArray:@[@"hash", @"superclass", @"description", @"debugDescription"]];
    [propertyNames removeObjectsInArray:[[self class] unsavedPropertyList]];
    return propertyNames;
}

+ (NSArray *)unsavedPropertyList {
    return @[];
}

+ (BOOL)hasUniqueId {
    return YES;
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
            [output appendFormat:@"_%@", [[NSString stringWithCharacters:&c length:1] lowercaseString]];
        } else {
            [output appendFormat:@"%C", c];
        }
    }
    return output;
}

- (NSDictionary *)instanceMapping {
    __block NSMutableDictionary *instanceMap = [[NSMutableDictionary alloc] init];
    NSDictionary *mappingDictionary = [[self class] columnToPropertyMapping];
    [mappingDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if([self valueForKey:(NSString *)obj]) [instanceMap setObject:[self valueForKey:(NSString *)obj] forKey:key];
    }];
    return instanceMap;
}

- (void)remove {
    NSString *deleteSQL = [NSString stringWithFormat:@"DELETE FROM %@ WHERE unique_id=:unique_id", [[self class] tableName]];
    NSDictionary *parameterDictionary = @{@"unique_id" : self.uniqueId};
    [[KStorageManager sharedManager] queryUpdate:^(FMDatabase *database) {
        [database executeUpdate:deleteSQL withParameterDictionary:parameterDictionary];
    }];
}

- (void)save {
    if(self.uniqueId) {
        NSString *columnKeys = [[self instanceMapping].allKeys componentsJoinedByString:@", "];
        NSString *valueKeys   = [@":" stringByAppendingString:[[self instanceMapping].allKeys componentsJoinedByString:@", :"]];
        NSString *insertOrReplaceSQL = [NSString stringWithFormat:@"insert or replace into %@ (%@) values(%@)", [self.class tableName], columnKeys, valueKeys];
        
        [[KStorageManager sharedManager] queryUpdate:^(FMDatabase *database) {
            [database executeUpdate:insertOrReplaceSQL withParameterDictionary:[self instanceMapping]];
        }];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:[[self class] notificationChannel] object:self userInfo:nil];
    }
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
    return objects;
}

+ (instancetype)findByUniqueId:(NSString *)uniqueId {
    if([self hasUniqueId]) {
        NSString *findByUniqueIdSQL = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE unique_id=:unique_id", [[self class] tableName]];
        NSDictionary *parameterDictionary = @{@"unique_id" : uniqueId};
        FMResultSet *result = [[KStorageManager sharedManager] querySelect:^FMResultSet *(FMDatabase *database) {
            return [database executeQuery:findByUniqueIdSQL withParameterDictionary:parameterDictionary];
        }];
        if(result.next) return [[self alloc] initWithResultSetRow:result.resultDictionary];
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
    
    FMResultSet *resultSet = [[KStorageManager sharedManager] querySelect:^FMResultSet *(FMDatabase *database) {
        return [database executeQuery:selectSQL withParameterDictionary:parameterDictionary];
    }];
    
    if(resultSet.next) {
        KDatabaseObject *object = [[self alloc] initWithResultSetRow:resultSet.resultDictionary];
        [resultSet close];
        return object;
    }else {
        return nil;
    }
}

//TODO: not sure if this is worth the performance hit to index columns for IN
/*
+ (NSArray *)findAllByDictionary:(NSDictionary *)dictionary {
    NSMutableArray *conditions = [[NSMutableArray alloc] init];
    for(NSString *key in [dictionary allKeys]) {
        if(![[self storedPropertyList] containsObject:key]) return nil;
        if([dictionary[key] isKindOfClass:[NSArray class]]) {
            NSMutableArray *inConditions = [[NSMutableArray alloc] init];
            for(int i = 0; i < ((NSArray *)dictionary[key]).count; i++) {
                [inConditions addObject:@"?"];
            }
            [conditions addObject:[NSString stringWithFormat:@"%@ IN (%@)", [self propertyToColumnMapping][key], [inConditions componentsJoinedByString:@", "]]];
        }else {
            [conditions addObject:[NSString stringWithFormat:@"%@ = :%@", [self propertyToColumnMapping][key], [self propertyToColumnMapping][key]]];
        }
    }
    NSString *selectSQL = [NSString stringWithFormat:@"select * from %@ where %@", [self tableName], [conditions componentsJoinedByString:@" AND "]];
    
    NSMutableDictionary *parameterDictionary = [[NSMutableDictionary alloc] init];
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [parameterDictionary setObject:obj forKey:[self columnNameFromProperty:key]];
    }];
    
    FMResultSet *resultSet = [[KStorageManager sharedManager] querySelect:^FMResultSet *(FMDatabase *database) {
        return [database executeQuery:selectSQL withParameterDictionary:parameterDictionary];
    }];
    
    NSMutableArray *objects = [[NSMutableArray alloc] init];
    while(resultSet.next) [objects addObject:[[self alloc] initWithResultSetRow:resultSet.resultDictionary]];
    [resultSet close];
    return objects;
}
*/

- (instancetype)initWithUniqueId:(NSString *)uniqueId {
    self = [super init];
    if(self) _uniqueId = uniqueId;
    return self;
}

- (instancetype)initWithResultSetRow:(NSDictionary *)resultSetRow {
    self = [super init];
    [[[self class] columnToPropertyMapping] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if(resultSetRow[key]) [self setValue:resultSetRow[key] forKey:obj];
    }];
    return self;
}

+ (NSString *)tableName {
    return NSStringFromClass([self class]);
}

@end
