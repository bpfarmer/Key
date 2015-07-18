//
//  KAttachment.h
//  Key
//
//  Created by Brendan Farmer on 4/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KDatabaseObject.h"
#import "KSendable.h"

@class AttachmentKey;

@interface KAttachment : KDatabaseObject <KSendable>

@property (nonatomic, readonly) NSData *cipherText;
@property (nonatomic, readonly) NSData *mac;
@property (nonatomic, readonly) NSString *attachmentKeyId;

- (instancetype)initWithObject:(KDatabaseObject *)object;
- (instancetype)initWithCipherText:(NSData *)cipherText mac:(NSData *)mac attachmentKeyId:(NSString *)attachmentKeyId;

- (AttachmentKey *)attachmentKey;

@end
