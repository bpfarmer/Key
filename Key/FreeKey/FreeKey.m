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
#import "CheckDevicesRequest.h"

@implementation FreeKey

+ (dispatch_queue_t)sharedQueue {
    static dispatch_once_t pred;
    static dispatch_queue_t sharedDispatchQueue;
    
    dispatch_once(&pred, ^{
        sharedDispatchQueue = dispatch_queue_create("FreeKeyQueue", NULL);
    });
    
    return sharedDispatchQueue;
}


+ (TOCFuture *)prepareSessionsForRecipientIds:(NSArray *)recipientIds {
    TOCFutureSource *futureDevicesAndSessions = [TOCFutureSource new];
    TOCFuture *futureDevices = [CheckDevicesRequest makeRequestWithUserIds:recipientIds];
    [futureDevices thenDo:^(id value) {
        [futureDevicesAndSessions trySetResult:[KUser asyncFindByIds:recipientIds]];
        /*TOCFuture *futureUsers = [KUser asyncFindByIds:recipientIds];
        [futureUsers thenDo:^(id value) {
            NSMutableArray *futureSessions = [NSMutableArray new];
            for(NSString *recipientId in recipientIds) {
                for(KDevice *device in [KDevice devicesForUserId:recipientId]) {
                    [futureSessions addObject:[self sessionWithReceiverDeviceId:device.deviceId]];
                }
            }
            [futureDevicesAndSessions trySetResult:futureSessions.toc_finallyAll];
        }];*/
    }];
    return futureDevicesAndSessions.future;
}


+ (TOCFuture *)sessionWithReceiverDeviceId:(NSString *)receiverDeviceId{
    TOCFutureSource *resultSource = [TOCFutureSource new];
    Session *session = [Session findByDictionary:@{@"receiverDeviceId" : receiverDeviceId}];
    if(session != nil) {
        [resultSource trySetResult:session];
    }else {
        TOCFuture *futureKeyExchange = [KUser asyncRetrieveKeyExchangeWithRemoteDeviceId:receiverDeviceId];
        [futureKeyExchange thenDo:^(KDatabaseObject *keyExchange) {
            dispatch_async([self sharedQueue], ^{
                Session *session = [Session findByDictionary:@{@"receiverDeviceId" : receiverDeviceId}];
                if(session != nil) {
                    [resultSource trySetResult:session];
                }else {
                    KUser *localUser = [KAccountManager sharedManager].user;
                    [FreeKey processNewKeyExchange:keyExchange localDeviceId:localUser.currentDeviceId localIdentityKey:localUser.identityKey];
                    [resultSource trySetResult:[Session findByDictionary:@{@"receiverDeviceId" : receiverDeviceId}]];
                }
            });
        }];
    }
    return resultSource.future;
}

+ (void)sendEncryptableObject:(KDatabaseObject *)encryptableObject recipientIds:(NSArray *)recipientIds {
    for(KDevice *device in [KDevice devicesForUserIds:recipientIds]) {
        TOCFuture *futureSession = [self sessionWithReceiverDeviceId:device.deviceId];
        [futureSession thenDo:^(Session *session) {
            dispatch_async([self sharedQueue], ^{
                [self sendEncryptableObject:encryptableObject session:session];
            });
        }];
    }
}

+ (void)sendEncryptableObject:(KDatabaseObject *)encryptableObject attachableObjects:(NSArray *)attachableObjects recipientIds:(NSArray *)recipientIds {
    AttachmentKey *attachmentKey = [[AttachmentKey alloc] init];
    [attachmentKey save];
    NSMutableArray *cipherAttachments = [NSMutableArray new];
    for(KDatabaseObject *attachableObject in attachableObjects) {
        [cipherAttachments addObject:[attachmentKey encryptObject:attachableObject]];
    }
    KUser *localUser = [KAccountManager sharedManager].user;
    for(KDevice *device in [KDevice devicesForUserIds:recipientIds]) {
        TOCFuture *futureSession = [self sessionWithReceiverDeviceId:device.deviceId];
        [futureSession thenDo:^(Session *session) {
            dispatch_async([self sharedQueue], ^{
                [self sendEncryptableObject:encryptableObject session:session];
                [self sendEncryptableObject:attachmentKey session:session];
            });
        }];
        for(NSData *cipherAttachment in cipherAttachments) {
            Attachment *attachment = [[Attachment alloc] initWithSenderId:localUser.currentDeviceId receiverId:device.deviceId cipherText:cipherAttachment mac:nil attachmentKeyId:attachmentKey.uniqueId];
            [SendAttachmentRequest makeRequestWithAttachment:attachment];
        }
    }
}

+ (void)sendEncryptableObject:(KDatabaseObject *)encryptableObject session:(Session *)session {
    EncryptedMessage *encryptedMessage = [session encryptMessage:[NSKeyedArchiver archivedDataWithRootObject:encryptableObject]];
    [SendMessageRequest makeRequestWithSendableMessage:encryptedMessage];
}

+ (void)decryptAndSaveEncryptedMessage:(EncryptedMessage *)encryptedMessage {
    TOCFuture *futureSession = [self sessionWithReceiverDeviceId:encryptedMessage.senderId];
    [futureSession thenDo:^(Session *session) {
        dispatch_async([self sharedQueue], ^{
            [self decryptAndSaveEncryptedMessage:encryptedMessage session:session];
        });
    }];
}

+ (KDatabaseObject *)decryptAndSaveEncryptedMessage:(EncryptedMessage *)encryptedMessage session:(Session *)session {
    NSData *decryptedData = [session decryptMessage:encryptedMessage];
    if(decryptedData != nil) {
        KDatabaseObject *object = (KDatabaseObject *)[NSKeyedUnarchiver unarchiveObjectWithData:decryptedData];
        [object save];
        return object;
    }
    return nil;
}

+ (void)decryptAndSaveAttachments:(NSArray *)attachments {
    dispatch_async([self sharedQueue], ^{
        for(Attachment *attachment in attachments) [self decryptAndSaveAttachment:attachment];
    });
}

+ (void)decryptAndSaveAttachment:(Attachment *)attachment {
    AttachmentKey *attachmentKey = [AttachmentKey findById:attachment.attachmentKeyId];
    if(attachmentKey) {
        NSLog(@"TRYING TO DECRYPT ATTACHMENT: %@", attachment);
        KDatabaseObject *object = [attachmentKey decryptCipherText:attachment.serializedData];
        [object save];
        NSLog(@"SAVED OBJECT: %@", object);
    }else {
        NSLog(@"COULDN'T FIND ATTACHMENT");
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
        [preKeys addObject:[self base64EncodedPreKeyDictionary:preKey]];
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
        NSLog(@"SUCCESSFULLY RECOGNIZED %@ AS PREKEY", keyExchange);
        PreKey *preKey = (PreKey *)keyExchange;
        NSString *remoteUserId = [preKey.userId componentsSeparatedByString:@"_"].firstObject;
        [KDevice addDeviceForUserId:remoteUserId deviceId:preKey.userId];
        Session *session = [[Session alloc] initWithSenderDeviceId:localDeviceId receiverDeviceId:preKey.userId];
        PreKeyExchange *preKeyExchange = [session addSenderBaseKey:[Curve25519 generateKeyPair] senderIdentityKey:localIdentityKey receiverPreKey:preKey receiverPublicKey:preKey.publicKey];
        NSLog(@"GENERATED PKE: %@", preKeyExchange);
        [SendPreKeyExchangeRequest makeRequestWithPreKeyExchange:preKeyExchange];
        return session;
    }else if([keyExchange isKindOfClass:[PreKeyExchange class]]) {
        PreKeyExchange *preKeyExchange = (PreKeyExchange *)keyExchange;
        NSString *remoteUserId = [preKeyExchange.senderId componentsSeparatedByString:@"_"].firstObject;
        [KDevice addDeviceForUserId:remoteUserId deviceId:preKeyExchange.senderId];
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
