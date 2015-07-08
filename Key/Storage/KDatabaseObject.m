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

@implementation KDatabaseObject

+ (void)createTable {
}

+ (void)dropTable {
    NSString *dropTableSQL = [NSString stringWithFormat:@"drop table %@;", [self class]];
    [[KStorageManager sharedManager] queryUpdate:^(FMDatabase *database) {
        [database executeUpdate:dropTableSQL];
    }];
}

+ (NSArray *)storedPropertyList {
    NSMutableArray *propertyNames = [[NSMutableArray alloc] init];
    [propertyNames addObject:kMappingUniqueId];
    unsigned int propertyCount = 0;
    objc_property_t *properties = class_copyPropertyList([self class], &propertyCount);
    for (unsigned int i = 0; i < propertyCount; ++i)
    {
        objc_property_t property = properties[i];
        [propertyNames addObject:[NSString stringWithUTF8String:property_getName(property)]];
    }
    [propertyNames removeObjectsInRange:NSMakeRange([propertyNames count] - 4, 4)];
    [propertyNames removeObjectsInArray:[[self class] unsavedPropertyList]];
    return propertyNames;
}

+ (NSArray *)unsavedPropertyList {
    return @[];
}

+ (NSDictionary *)propertyMapping {
    NSMutableDictionary *mappingDictionary = [[NSMutableDictionary alloc] init];
    NSArray *storedProperties = [[self class] storedPropertyList];
    for(NSString *storedProperty in storedProperties) {
        NSMutableString *output = [NSMutableString string];
        NSCharacterSet *uppercase = [NSCharacterSet uppercaseLetterCharacterSet];
        for (NSInteger idx = 0; idx < [storedProperty length]; idx += 1) {
            unichar c = [storedProperty characterAtIndex:idx];
            if ([uppercase characterIsMember:c]) {
                [output appendFormat:@"_%@", [[NSString stringWithCharacters:&c length:1] lowercaseString]];
            } else {
                [output appendFormat:@"%C", c];
            }
        }
        [mappingDictionary setObject:storedProperty forKey:output];
    }
    return [NSDictionary dictionaryWithDictionary:mappingDictionary];
}

- (NSDictionary *)instanceMapping {
    __block NSMutableDictionary *instanceMap = [[NSMutableDictionary alloc] init];
    NSDictionary *mappingDictionary = [[self class] propertyMapping];
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
        NSString *hashKeys   = [@":" stringByAppendingString:[[self instanceMapping].allKeys componentsJoinedByString:@", :"]];
        NSLog(@"COLUMN KEYS: %@, HASH KEYS: %@", columnKeys, hashKeys);
        NSString *insertOrReplaceSQL = [NSString stringWithFormat:@"insert or replace into %@ (%@) values(%@)", [self.class tableName], columnKeys, hashKeys];
        
        [[KStorageManager sharedManager] queryUpdate:^(FMDatabase *database) {
            [database executeUpdate:insertOrReplaceSQL withParameterDictionary:[self instanceMapping]];
        }];
    }
}

+ (FMResultSet *)all {
    NSString *findAllSQL = [NSString stringWithFormat:@"select * from %@", [self.class tableName]];
    return [[KStorageManager sharedManager] querySelect:^FMResultSet *(FMDatabase *database) {
        return [database executeQuery:findAllSQL];
    }];
}

+ (instancetype)findByUniqueId:(NSString *)uniqueId {
    NSString *findByUniqueIdSQL = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE unique_id=:unique_id", [[self class] tableName]];
    NSDictionary *parameterDictionary = @{@"unique_id" : uniqueId};
    FMResultSet *result = [[KStorageManager sharedManager] querySelect:^FMResultSet *(FMDatabase *database) {
        return [database executeQuery:findByUniqueIdSQL withParameterDictionary:parameterDictionary];
    }];
    return [[self alloc] initWithResultSet:result];
}

- (instancetype)initWithUniqueId:(NSString *)uniqueId {
    self = [super init];
    if(self) _uniqueId = uniqueId;
    return self;
}

- (instancetype)initWithResultSet:(FMResultSet *)resultSet {
    self = [super init];
    if(resultSet.next) {
        [[[self class] propertyMapping] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if(resultSet.resultDictionary[key]) [self setValue:resultSet.resultDictionary[key] forKey:obj];
        }];
        [resultSet close];
        return self;
    }else {
        return nil;
    }
}

+ (NSString *)tableName {
    return NSStringFromClass([self class]);
}

@end
