//
//  Attachment.h
//  Key
//
//  Created by Brendan Farmer on 7/21/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KDatabaseObject.h"
#import "KSendable.h"

@class AttachmentKey;

@interface Attachment : KDatabaseObject <KSendable>

@property (nonatomic, readonly) NSString *senderId;
@property (nonatomic, readonly) NSString *receiverId;
@property (nonatomic, readonly) NSData *cipherText;
@property (nonatomic, readonly) NSData *serializedData;
@property (nonatomic, readonly) NSData *mac;
@property (nonatomic, readonly) NSString *attachmentKeyId;

- (instancetype)initWithSenderId:(NSString *)senderId receiverId:(NSString *)receiverId cipherText:(NSData *)cipherText mac:(NSData *)mac attachmentKeyId:(NSString *)attachmentKeyId;
- (instancetype)initWithSenderId:(NSString *)senderId receiverId:(NSString *)receiverId serializedData:(NSData *)serializedData attachmentKeyId:(NSString *)attachmentKeyId;
- (AttachmentKey *)attachmentKey;
+ (NSArray *)remoteKeys;

@end
