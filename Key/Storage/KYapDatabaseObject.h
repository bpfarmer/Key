//
//  KYapDatabaseObject.h
//  Key
//
//  Created by Brendan Farmer on 1/26/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YapDatabaseRelationshipNode.h"
#import "YapDatabaseTransaction.h"

@interface KYapDatabaseObject : NSObject <NSSecureCoding>

/**
 *  Initializes a new database object with a unique identifier
 *
 *  @param uniqueId Key used for the key-value store
 *
 *  @return Initialized object
 */

- (instancetype)initWithUniqueId:(NSString*)uniqueId;

/**
 *  Returns the collection to which the object belongs.
 *
 *  @return Key (string) identifying the collection
 */

+ (NSString*)collection;

/**
 *  Fetches the object with the provided identifier
 *
 *  @param uniqueId    Unique identifier of the entry in a collection
 *  @param transaction Transaction used for fetching the object
 *
 *  @return Returns and instance of the object or nil if non-existent
 */

+ (instancetype) fetchObjectWithUniqueId:(NSString*)uniqueId transaction:(YapDatabaseReadTransaction*)transaction;

+ (instancetype) fetchObjectWithUniqueId:(NSString *)uniqueId;

/**
 *  Saves the object with a new YapDatabaseConnection
 */

- (void)save;

/**
 *  Saves the object with the provided transaction
 *
 *  @param transaction Database transaction
 */

- (void)saveWithTransaction:(YapDatabaseReadWriteTransaction*)transaction;

/**
 *  The unique identifier of the stored object
 */


@property (nonatomic) NSString *uniqueId;


- (void)removeWithTransaction:(YapDatabaseReadWriteTransaction*)transaction;
- (void)remove;

@end
