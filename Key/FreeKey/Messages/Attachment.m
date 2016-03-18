//
//  Attachment.m
//  Key
//
//  Created by Brendan Farmer on 7/21/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "Attachment.h"
#import "FreeKey.h"
#import "AttachmentKey.h"
#import "AES_CBC.h"

@implementation Attachment

- (instancetype)initWithSenderId:(NSString *)senderId receiverId:(NSString *)receiverId cipherText:(NSData *)cipherText mac:(NSData *)mac attachmentKeyId:(NSString *)attachmentKeyId {
    self = [super init];
    
    if(self) {
        _senderId        = senderId;
        _receiverId      = receiverId;
        _cipherText      = cipherText;
        _mac             = mac;
        _serializedData  = cipherText;
        _attachmentKeyId = attachmentKeyId;
    }
    
    return self;
}

- (instancetype)initWithSenderId:(NSString *)senderId receiverId:(NSString *)receiverId serializedData:(NSData *)serializedData attachmentKeyId:(NSString *)attachmentKeyId {
    self = [super init];
    
    if(self) {
        _senderId        = senderId;
        _receiverId      = receiverId;
        _serializedData  = serializedData;
        _cipherText      = serializedData;
        _attachmentKeyId = attachmentKeyId;
    }
    
    return self;
}

- (AttachmentKey *)attachmentKey {
    return [AttachmentKey findById:self.attachmentKeyId];
}

+ (NSArray *)remoteKeys {
    return @[@"senderId", @"receiverId", @"serializedData", @"attachmentKeyId"];
}

+ (NSString *)remoteAlias {
    return kAttachmentRemoteAlias;
}

@end