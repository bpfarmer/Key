//
//  FreeKey.m
//  Key
//
//  Created by Brendan Farmer on 3/9/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "FreeKey.h"
#import "PreKey.h"
#import "KUser.h"
#import <25519/Curve25519.h>
#import <25519/Ed25519.h>
#import "KStorageManager.h"
#import "Session.h"
#import "PreKeyExchange.h"
#import "EncryptedMessage.h"
#import "KAccountManager.h"
#import "NSData+Base64.h"
#import "KSendable.h"
#import "RootChain.h"
#import "MessageKey.h"
#import "CollapsingFutures.h"
#import "KDevice.h"
#import "CheckDevicesRequest.h"
#import "AttachmentKey.h"
#import "Attachment.h"
#import "SendMessageRequest.h"
#import "SendAttachmentRequest.h"
#import "SendPreKeysRequest.h"
#import "SendPreKeyExchangeRequest.h"

@implementation FreeKey

+ (TOCFuture *)sessionWithReceiverDeviceId:(NSString *)receiverDeviceId{
    TOCFutureSource *resultSource = [TOCFutureSource new];
    Session *session = [Session findByDictionary:@{@"receiverDeviceId" : receiverDeviceId}];
    if(session != nil) [resultSource trySetResult:session];
    else {
        TOCFuture *futureSession = [KUser asyncRetrieveKeyExchangeWithRemoteDeviceId:receiverDeviceId];
        [futureSession thenDo:^(Session *session) {
            [resultSource trySetResult:session];
        }];
    }
    return resultSource.future;
}

+ (void)sendEncryptableObject:(KDatabaseObject *)encryptableObject recipientId:(NSString *)recipientId {
    for(KDevice *device in [KDevice devicesForUserId:recipientId]) {
        TOCFuture *futureSession = [self sessionWithReceiverDeviceId:device.deviceId];
        [futureSession thenDo:^(Session *session) {
            EncryptedMessage *encryptedMessage = [session encryptMessage:[NSKeyedArchiver archivedDataWithRootObject:encryptableObject]];
            [SendMessageRequest makeRequestWithSendableMessage:encryptedMessage];
        }];
    }
}

+ (void)decryptAndSaveEncryptedMessage:(EncryptedMessage *)encryptedMessage {
    NSString *remoteDeviceId = encryptedMessage.senderId;
    TOCFuture *futureSession = [FreeKey sessionWithReceiverDeviceId:remoteDeviceId];
    [futureSession thenDo:^(Session *session) {
        NSData *decryptedData = [session decryptMessage:encryptedMessage];
        [((KDatabaseObject *)[NSKeyedUnarchiver unarchiveObjectWithData:decryptedData]) save];
    }];
}

+ (void)sendAttachableObject:(KDatabaseObject *)object recipientIds:(NSArray *)recipientIds {
    dispatch_queue_t queue = dispatch_queue_create([kEncryptObjectQueue cStringUsingEncoding:NSASCIIStringEncoding], NULL);
    dispatch_async(queue, ^{
        AttachmentKey *attachmentKey = [[AttachmentKey alloc] init];
        [attachmentKey save];
        for(NSString *recipientId in recipientIds) [self sendEncryptableObject:attachmentKey recipientId:recipientId];
        NSData *cipherText = [attachmentKey encryptObject:object];
        KUser *localUser = [KAccountManager sharedManager].user;
        for(NSString *recipientId in recipientIds) {
            for(KDevice *device in [KDevice devicesForUserId:recipientId]) {
                Attachment *attachment = [[Attachment alloc] initWithSenderId:localUser.currentDeviceId receiverId:device.deviceId cipherText:cipherText mac:nil attachmentKeyId:attachmentKey.uniqueId];
                [SendAttachmentRequest makeRequestWithAttachment:attachment];

            }
        }
    });
}

+ (void)decryptAndSaveAttachment:(Attachment *)attachment {
    AttachmentKey *attachmentKey = [AttachmentKey findById:attachment.attachmentKeyId];
    if(attachmentKey) {
        KDatabaseObject *object = [attachmentKey decryptCipherText:attachment.cipherText];
        [object save];
    }
}

#pragma mark - Encryption and Decryption Wrappers

+ (void)generatePreKeysForLocalIdentityKey:(ECKeyPair *)localIdentityKey localDeviceId:(NSString *)localDeviceId  {
    NSMutableArray *preKeys = [[NSMutableArray alloc] init];
    for(int index = 0; index < 100; index++) {
        ECKeyPair *baseKeyPair = [Curve25519 generateKeyPair];
        NSString *uniquePreKeyId = [NSString stringWithFormat:@"%@_%f_%d", localDeviceId, [[NSDate date] timeIntervalSince1970], index];
        NSData *signature = [Ed25519 sign:baseKeyPair.publicKey withKeyPair:localIdentityKey];
        PreKey *preKey = [[PreKey alloc] initWithUniqueId:uniquePreKeyId
                                                   userId:localDeviceId
                                            basePublicKey:baseKeyPair.publicKey
                                                signature:signature
                                                publicKey:localIdentityKey.publicKey
                                              baseKeyPair:baseKeyPair];
        [preKey save];
        [preKeys addObject:preKey];
    }
    [SendPreKeysRequest makeRequestWithPreKeys:preKeys];
}

+ (NSDictionary *)base64EncodedPreKeyDictionary:(PreKey *)preKey {
    NSMutableDictionary *objectDictionary = [[NSMutableDictionary alloc] init];
    [[PreKey remoteKeys] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSObject *property = [preKey dictionaryWithValuesForKeys:@[obj]][obj];
        if([property isKindOfClass:[NSData class]]) {
            NSData *dataProperty = (NSData *)property;
            NSString *encodedString = [dataProperty base64EncodedString];
            [objectDictionary addEntriesFromDictionary:@{obj : encodedString}];
        }else {
            [objectDictionary addEntriesFromDictionary:@{obj : property}];
        }
    }];
    return objectDictionary;
}


+ (Session *)processNewKeyExchange:(NSObject *)keyExchange localDeviceId:(NSString *)localDeviceId localIdentityKey:(ECKeyPair *)localIdentityKey {
    if([keyExchange isKindOfClass:[PreKey class]]) {
        PreKey *preKey = (PreKey *)keyExchange;
        NSString *remoteUserId = [preKey.userId componentsSeparatedByString:@"_"].firstObject;
        [KDevice addDeviceForUserId:remoteUserId deviceId:preKey.userId];
        Session *session = [[Session alloc] initWithSenderDeviceId:localDeviceId receiverDeviceId:preKey.userId];
        PreKeyExchange *preKeyExchange = [session addSenderBaseKey:[Curve25519 generateKeyPair] senderIdentityKey:localIdentityKey receiverPreKey:preKey receiverPublicKey:preKey.publicKey];
        [SendPreKeyExchangeRequest makeRequestWithPreKeyExchange:preKeyExchange];
        return session;
    }else if([keyExchange isKindOfClass:[PreKeyExchange class]]) {
        PreKeyExchange *preKeyExchange = (PreKeyExchange *)keyExchange;
        [KDevice addDeviceForUserId:preKeyExchange.senderId deviceId:preKeyExchange.senderId];
        Session *session = [[Session alloc] initWithSenderDeviceId:localDeviceId receiverDeviceId:preKeyExchange.senderId];
        PreKey *ourPreKey = [PreKey findById:(NSString *)((PreKeyExchange *)keyExchange).preKeyId];
        if(ourPreKey) {
            [session addSenderPreKey:ourPreKey senderIdentityKey:localIdentityKey receiverPreKeyExchange:preKeyExchange receiverPublicKey:preKeyExchange.senderPublicKey];
            return session;
        }
    }
    return nil;
}

@end
