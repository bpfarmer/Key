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

- (instancetype)initWithObject:(KDatabaseObject *)object {
    self = [super init];
    
    if(self) {
        AttachmentKey *attachmentKey = [[AttachmentKey alloc] init];
        [attachmentKey save];
        _attachmentKeyId = attachmentKey.uniqueId;
        NSData *serializedObject = [NSKeyedArchiver archivedDataWithRootObject:object];
        _cipherText = [AES_CBC encryptCBCMode:serializedObject withKey:attachmentKey.cipherKey withIV:attachmentKey.iv];
    }
    return self;
}

- (instancetype)initWithCipherText:(NSData *)cipherText mac:(NSData *)mac attachmentKeyId:(NSString *)attachmentKeyId {
    self = [super init];
    
    if(self) {
        _cipherText = cipherText;
        _mac        = mac;
        _attachmentKeyId = attachmentKeyId;
    }
    
    return self;
}

- (AttachmentKey *)attachmentKey {
    return [AttachmentKey findById:self.attachmentKeyId];
}

+ (NSArray *)remoteKeys {
    return @[@"cipherText", @"hmac", @"messageUniqueId"];
}

+ (NSString *)remoteAlias {
    return kAttachmentRemoteAlias;
}

@end