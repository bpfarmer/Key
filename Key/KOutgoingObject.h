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

- (instancetype)initWithObject:(id<KEncryptable>)object recipients:(NSArray *)recipients;
+ (void)confirmDeliveryOfObject:(id<KEncryptable>)object toRecipient:(NSString *)recipientId;

@end
