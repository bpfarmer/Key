//
//  KDatabaseObject.h
//  Key
//
//  Created by Brendan Farmer on 7/6/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KDatabaseObject : NSObject

@property (nonatomic, readwrite) NSString *uniqueId;

- (void)save;
- (void)remove;
- (void)createTable;
- (void)dropTable;
- (NSString *)tableName;

@end
