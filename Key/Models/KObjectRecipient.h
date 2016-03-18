//
//  KObjectRecipient.h
//  Key
//
//  Created by Brendan Farmer on 8/26/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KDatabaseObject.h"

@interface KObjectRecipient : KDatabaseObject

@property (nonatomic) NSString *objectId;
@property (nonatomic) NSString *recipientId;

- (instancetype)initWithObjectId:(NSString *)objectId recipientId:(NSString *)recipientId;

@end
