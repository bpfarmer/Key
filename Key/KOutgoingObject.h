//
//  KOutgoingObject.h
//  Key
//
//  Created by Brendan Farmer on 6/14/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KDatabaseObject.h"
#import "KEncryptable.h"

@interface KOutgoingObject : KDatabaseObject

@property (nonatomic) NSArray *recipients;

- (instancetype)initWithObject:(KDatabaseObject *)object recipients:(NSArray *)recipients;
+ (void)confirmDeliveryOfObject:(KDatabaseObject *)object toRecipient:(NSString *)recipientId;

@end
