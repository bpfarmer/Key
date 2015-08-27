//
//  ObjectRecipient.h
//  Key
//
//  Created by Brendan Farmer on 8/26/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KDatabaseObject.h"

@interface ObjectRecipient : KDatabaseObject

@property (nonatomic) NSString *type;
@property (nonatomic) NSString *objectId;
@property (nonatomic) NSString *recipientId;

- (instancetype)initWithType:(NSString *)type objectId:(NSString *)objectId recipientId:(NSString *)recipientId;

@end
