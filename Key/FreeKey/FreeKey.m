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
#import "IdentityKey.h"
#import "KStorageManager.h"
#import "Session.h"
#import "PreKeyExchange.h"
#import "HttpManager.h"
#import "EncryptedMessage.h"
#import "KAccountManager.h"
#import "KMessage.h"
#import "NSData+Base64.h"
#import "KSendable.h"
#import "FreeKeySessionManager.h"
#import "RootChain.h"
#import "MessageKey.h"
#import "KOutgoingObject.h"
#import "CollapsingFutures.h"
#import "KDevice.h"
#import "CheckDevicesRequest.h"
#import "AttachmentKey.h"
#import "Attachment.h"
#import "SendMessageRequest.h"
#import "SendAttachmentRequest.h"

@implementation FreeKey

+ (void)sendEncryptableObject:(KDatabaseObject *)encryptableObject recipientIds:(NSArray *)recipientIds {
    dispatch_queue_t queue = dispatch_queue_create([kEncryptObjectQueue cStringUsingEncoding:NSASCIIStringEncoding], NULL);
    dispatch_async(queue, ^{
        TOCFuture *futureDeviceCheck = [CheckDevicesRequest makeRequestWithUserIds:recipientIds];
        [futureDeviceCheck thenDo:^(id value) {
            KUser *localUser = [KAccountManager sharedManager].user;
            [recipientIds enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSLog(@"RECIPIENT ID PROVIDED: %@", obj);
                KUser *remoteUser = [KUser findById:obj];
                if(!remoteUser) {
                    TOCFuture *futureUser = [KUser asyncRetrieveWithUniqueId:obj];
                    [futureUser thenDo:^(KUser *retrievedUser) {
                        [self sendEncryptableObject:encryptableObject localUser:localUser remoteUser:retrievedUser];
                    }];
                }else {
                    [self sendEncryptableObject:encryptableObject localUser:localUser remoteUser:remoteUser];
                }
            }];
        }];
    });
}

+ (void)sendEncryptableObject:(KDatabaseObject *)encryptableObject localUser:(KUser *)localUser remoteUser:(KUser *)remoteUser {
    for(KDevice *device in [KDevice devicesForUserId:remoteUser.uniqueId]) {
        NSLog(@"TRYING TO CREATE SESSION FOR DEVICE: %@", device);
        if(!device.isCurrentDevice) {
            TOCFuture *futureSession = [[FreeKeySessionManager sharedManager] sessionWithLocalUser:localUser remoteUser:remoteUser deviceId:device.deviceId];
            [futureSession thenDo:^(Session *session) {
                EncryptedMessage *encryptedMessage = [self encryptObject:encryptableObject session:session];
                [SendMessageRequest makeRequestWithSendableMessage:encryptedMessage];
            }];
        }
    }
}

+ (void)decryptAndSaveEncryptedMessage:(EncryptedMessage *)encryptedMessage {
    dispatch_queue_t queue = dispatch_queue_create([kEncryptObjectQueue cStringUsingEncoding:NSASCIIStringEncoding], NULL);
    
    dispatch_async(queue, ^{
        KUser *localUser   = [KAccountManager sharedManager].user;
        NSString *senderId = [encryptedMessage.senderId componentsSeparatedByString:@"_"].firstObject;
        NSString *senderDeviceId = encryptedMessage.senderId;
        KUser *remoteUser  = [KUser findById:senderId];
        NSLog(@"SENDER ID: %@ DEVICE ID: %@", senderId, senderDeviceId);
        if(remoteUser) {
            NSLog(@"REMOTE USER EXISTS");
            TOCFuture *futureSession = [[FreeKeySessionManager sharedManager] sessionWithLocalUser:localUser remoteUser:remoteUser deviceId:senderDeviceId];
            [futureSession thenDo:^(Session *session) {
                KDatabaseObject *decryptedObject = (KDatabaseObject *)[self decryptEncryptedMessage:encryptedMessage session:session];
                [decryptedObject save];
            }];
        }else {
            TOCFuture *futureUser = [KUser asyncRetrieveWithUniqueId:senderId];
            [futureUser thenDo:^(KUser *retrievedUser) {
                NSLog(@"RETRIEVED REMOTE USER: %@", remoteUser);
                TOCFuture *futureSession = [[FreeKeySessionManager sharedManager] sessionWithLocalUser:localUser remoteUser:retrievedUser deviceId:senderDeviceId];
                [futureSession thenDo:^(Session *session) {
                    KDatabaseObject *decryptedObject = (KDatabaseObject *)[self decryptEncryptedMessage:encryptedMessage session:session];
                    [decryptedObject save];
                }];
            }];
        }
    });
}

+ (void)sendAttachableObject:(KDatabaseObject *)object recipientIds:(NSArray *)recipientIds {
    dispatch_queue_t queue = dispatch_queue_create([kEncryptObjectQueue cStringUsingEncoding:NSASCIIStringEncoding], NULL);
    dispatch_async(queue, ^{
        AttachmentKey *attachmentKey = [[AttachmentKey alloc] init];
        [attachmentKey save];
        [self sendEncryptableObject:attachmentKey recipientIds:recipientIds];
        NSData *cipherText = [attachmentKey encryptObject:object];
        KUser *localUser = [KAccountManager sharedManager].user;
        for(NSString *recipientId in recipientIds) {
            KUser *remoteUser = [KUser findById:recipientId];
            if(!remoteUser) {
                TOCFuture *futureUser = [KUser asyncRetrieveWithUniqueId:recipientId];
                [futureUser thenDo:^(KUser *retrievedUser) {
                    [self sendAttachmentWithCipherText:cipherText attachmentKey:(AttachmentKey *)attachmentKey localUser:localUser remoteUser:remoteUser];
                }];
            }else {
                [self sendAttachmentWithCipherText:cipherText attachmentKey:(AttachmentKey *)attachmentKey localUser:localUser remoteUser:remoteUser];
            }
        }
    });
}

+ (void)sendAttachmentWithCipherText:(NSData *)cipherText attachmentKey:(AttachmentKey *)attachmentKey localUser:(KUser *)localUser remoteUser:(KUser *)remoteUser {
    for(KDevice *device in remoteUser.devices) {
        NSLog(@"CREATING ATTACHMENT FOR DEVICE ID: %@", device.deviceId);
        Attachment *attachment = [[Attachment alloc] initWithSenderId:localUser.currentDevice.deviceId receiverId:device.deviceId cipherText:cipherText mac:nil attachmentKeyId:attachmentKey.uniqueId];
        [SendAttachmentRequest makeRequestWithAttachment:attachment];
    }
}

+ (void)decryptAndSaveAttachment:(Attachment *)attachment {
    AttachmentKey *attachmentKey = [AttachmentKey findById:attachment.attachmentKeyId];
    if(attachmentKey) {
        KDatabaseObject *object = [attachmentKey decryptCipherText:attachment.cipherText];
        [object save];
    }
}

#pragma mark - Encryption and Decryption Wrappers
+ (EncryptedMessage *)encryptObject:(id<KEncryptable>)object session:(Session *)session {
    NSData *serializedObject = [NSKeyedArchiver archivedDataWithRootObject:object];
    EncryptedMessage *encryptedMessage = [session encryptMessage:serializedObject];
    [encryptedMessage addMetadataFromLocalUserId:session.senderDeviceId toRemoteUserId:session.receiverDeviceId];
    [session save];
    return encryptedMessage;
}

+ (KDatabaseObject *)decryptEncryptedMessage:(EncryptedMessage *)encryptedMessage session:(Session *)session {
    NSData *decryptedData = [session decryptMessage:encryptedMessage];
    [session save];
    return [NSKeyedUnarchiver unarchiveObjectWithData:decryptedData];
}

+ (NSArray *)generatePreKeysForLocalUser:(KUser *)localUser {
    int index = 0;
    NSMutableArray *preKeys  = [[NSMutableArray alloc] init];
    IdentityKey *identityKey = [localUser identityKey];
    NSString *deviceId       = localUser.currentDevice.deviceId;
    while(index < 100) {
        ECKeyPair *baseKeyPair = [Curve25519 generateKeyPair];
        NSString *uniquePreKeyId = [NSString stringWithFormat:@"%@_%f_%d", localUser.uniqueId, [[NSDate date] timeIntervalSince1970], index];
        NSData *preKeySignature = [Ed25519 sign:baseKeyPair.publicKey withKeyPair:identityKey.keyPair];
        PreKey *preKey = [[PreKey alloc] initWithUserId:localUser.uniqueId
                                               deviceId:deviceId
                                         signedPreKeyId:uniquePreKeyId
                                     signedPreKeyPublic:baseKeyPair.publicKey
                                  signedPreKeySignature:preKeySignature
                                            identityKey:localUser.publicKey
                                            baseKeyPair:baseKeyPair];
        [preKey setUniqueId:uniquePreKeyId];
        [preKey save];
        [preKeys addObject:[self base64EncodedPreKeyDictionary:preKey]];
        index++;
    }
    return [[NSArray alloc] initWithArray:preKeys];
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

@end
