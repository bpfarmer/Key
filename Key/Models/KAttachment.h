//
//  KAttachment.h
//  Key
//
//  Created by Brendan Farmer on 4/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KDatabaseObject.h"
#import "KSendable.h"

@interface KAttachment : KDatabaseObject <KSendable>

@property (nonatomic, readonly) NSData *cipherText;
@property (nonatomic, readonly) NSData *hmac;
@property (nonatomic, readonly) NSString *messageUniqueId;

- (instancetype)initWithCipherText:(NSData *)cipherText hmac:(NSData *)hmac messageUniqueId:(NSString *)messageUniqueId;

@end
