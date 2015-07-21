//
//  Attachment.h
//  Key
//
//  Created by Brendan Farmer on 7/21/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KDatabaseObject.h"

@class AttachmentKey;

@interface Attachment : KDatabaseObject

@property (nonatomic, readonly) NSData *cipherText;
@property (nonatomic, readonly) NSData *mac;
@property (nonatomic, readonly) NSString *attachmentKeyId;

- (instancetype)initWithObject:(KDatabaseObject *)object;
- (instancetype)initWithCipherText:(NSData *)cipherText mac:(NSData *)mac attachmentKeyId:(NSString *)attachmentKeyId;

- (AttachmentKey *)attachmentKey;

@end
