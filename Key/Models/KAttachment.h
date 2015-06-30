//
//  KAttachment.h
//  Key
//
//  Created by Brendan Farmer on 4/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KYapDatabaseObject.h"
#import "KEncryptable.h"

@interface KAttachment : KYapDatabaseObject <KEncryptable>

@property (nonatomic, readonly) NSData *media;
@property (nonatomic, readonly) NSString *type;
@property (nonatomic, readonly) NSData *hmac;
@property (nonatomic, readonly) NSString *parentUniqueId;

- (instancetype)initWithUniqueId:(NSString *)uniqueId media:(NSData *)media type:(NSString *)type hmac:(NSData *)hmac parentUniqueId:(NSString *)parentUniqueId;

@end
