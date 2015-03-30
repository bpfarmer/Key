//
//  FreeKeyPushManager.m
//  Key
//
//  Created by Brendan Farmer on 3/20/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "FreeKeyNetworkManager.h"
#import "PreKey.h"
#import "PreKeyExchange.h"
#import "EncryptedMessage.h"
#import "KUser.h"
#import "KMessage.h"
#import "KStorageManager.h"
#import "HttpManager.h"
#import "FreeKey.h"
#import "NSData+Base64.h"
#import "FreeKeySessionManager.h"
#import "KAccountManager.h"
#import <25519/Curve25519.h>
#import <25519/Ed25519.h>
#import "IdentityKey.h"
#import "CollapsingFutures.h"
#import "FreeKeyResponseHandler.h"
#import "Session.h"
#import "SendPreKeyExchangeRequest.h"
#import "SendMessageRequest.h"

@implementation FreeKeyNetworkManager

+ (instancetype)sharedManager {
    static FreeKeyNetworkManager *sharedMyManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (void)enqueueEncryptableObject:(id <KEncryptable>)object localUser:(KUser *)localUser remoteUser:(KUser *)remoteUser {
    dispatch_queue_t queue = dispatch_queue_create([kEncryptObjectQueue cStringUsingEncoding:NSASCIIStringEncoding], NULL);
    dispatch_async(queue, ^{
        Session *session = [[FreeKeySessionManager sharedManager] sessionWithLocalUser:localUser remoteUser:remoteUser];
        if(!session) {
            TOCFuture *futureKeyExchange = [localUser asyncRetrieveKeyExchangeWithRemoteUser:remoteUser];
            [futureKeyExchange thenDo:^(id keyExchange) {
                Session *newSession = [[FreeKeySessionManager sharedManager] processNewKeyExchange:keyExchange
                                                                                         localUser:localUser
                                                                                        remoteUser:remoteUser];
                if(newSession) {
                    // TODO: need to relate PKE with messages until it's acknowledged with a receipt
                    PreKeyExchange *preKeyExchange = [newSession preKeyExchange];
                    [preKeyExchange setSenderId:localUser.uniqueId];
                    [SendPreKeyExchangeRequest makeRequestWithPreKeyExchange:preKeyExchange];
                    [self encryptAndSendObject:object session:newSession localUser:localUser remoteUser:remoteUser];
                }
            }];
        }else {
            [self encryptAndSendObject:object session:session localUser:localUser remoteUser:remoteUser];
        }
    });
}

- (void)enqueueDecryptableMessage:(EncryptedMessage *)encryptedMessage toLocalUser:(KUser *)localUser {
    dispatch_queue_t queue = dispatch_queue_create([kDecryptObjectQueue cStringUsingEncoding:NSASCIIStringEncoding], NULL);
    dispatch_async(queue, ^{
        KUser *remoteUser = (KUser *)[[KStorageManager sharedManager] objectForKey:encryptedMessage.senderId
                                                                      inCollection:[KUser collection]];
        if(remoteUser) {
            [self decryptAndSaveMessage:encryptedMessage localUser:localUser remoteUser:remoteUser];
        }else {
            TOCFuture *futureUser = [KUser asyncRetrieveWithUniqueId:encryptedMessage.senderId];
            [futureUser thenDo:^(KUser *user){
                [self decryptAndSaveMessage:encryptedMessage localUser:localUser remoteUser:user];
            }];
        }
    });
}

- (void)encryptAndSendObject:(id <KEncryptable>)object
                     session:(Session *)session
                   localUser:(KUser *)localUser
                  remoteUser:(KUser *)remoteUser {
    EncryptedMessage *newEncryptedMessage = [FreeKey encryptObject:object session:session];
    [newEncryptedMessage addMetadataFromLocalUserId:localUser.uniqueId toRemoteUserId:remoteUser.uniqueId];
    [SendMessageRequest makeRequestWithSendableMessage:newEncryptedMessage];
}

- (void)decryptAndSaveMessage:(EncryptedMessage *)encryptedMessage
                    localUser:(KUser *)localUser
                   remoteUser:(KUser *)remoteUser {
    Session *session = [[FreeKeySessionManager sharedManager] sessionWithLocalUser:localUser remoteUser:remoteUser];
    if(!session) {
        PreKeyExchange *preKeyExchange = [[FreeKeySessionManager sharedManager] getPreKeyExchangeForUserId:remoteUser.uniqueId];
        if(preKeyExchange) {
            NSLog(@"PKE PUB KEY: %@", preKeyExchange.senderIdentityPublicKey);
            NSLog(@"PKE BASE KEY: %@", preKeyExchange.sentSignedBaseKey);
            Session *session = [[FreeKeySessionManager sharedManager] processNewPreKeyExchange:preKeyExchange
                                                                                     localUser:localUser
                                                                                    remoteUser:remoteUser];
            if(session) {
                id <KEncryptable> object = [FreeKey decryptEncryptedMessage:encryptedMessage session:session];
                [object save];
                [[KStorageManager sharedManager] removeObjectForKey:remoteUser.uniqueId inCollection:kPreKeyExchangeCollection];
            }
        }else {
            TOCFuture *futureKeyExchange = [localUser asyncRetrieveKeyExchangeWithRemoteUser:remoteUser];
            [futureKeyExchange thenDo:^(id keyExchange) {
                Session *newSession = [[FreeKeySessionManager sharedManager] processNewKeyExchange:keyExchange
                                                                                         localUser:localUser
                                                                                        remoteUser:remoteUser];
                if(newSession) {
                    id <KEncryptable> object = [FreeKey decryptEncryptedMessage:encryptedMessage session:newSession];
                    [object save];
                }
            }];
        }
    }
    if(session) {
        id <KEncryptable> object = [FreeKey decryptEncryptedMessage:encryptedMessage session:session];
        [object save];
    }
}

- (NSString *)getClassNameFromType:(NSString *)type {
    NSDictionary *classNames = @{kUserRemoteAlias : @"KUser"};
    return classNames[type];
}

#pragma mark - Generating PreKeys

- (NSArray *)generatePreKeysForLocalUser:(KUser *)localUser {
    int index = 0;
    NSMutableArray *preKeys = [[NSMutableArray alloc] init];
    while(index < 100) {
        ECKeyPair *baseKeyPair = [Curve25519 generateKeyPair];
        NSString *uniquePreKeyId = [NSString stringWithFormat:@"%@_%f_%d", localUser.uniqueId, [[NSDate date] timeIntervalSince1970], index];
        NSData *preKeySignature = [Ed25519 sign:baseKeyPair.publicKey withKeyPair:localUser.identityKey.keyPair];
        PreKey *preKey = [[PreKey alloc] initWithUserId:localUser.uniqueId
                                               deviceId:@"1"
                                         signedPreKeyId:uniquePreKeyId
                                     signedPreKeyPublic:baseKeyPair.publicKey
                                  signedPreKeySignature:preKeySignature
                                            identityKey:localUser.publicKey
                                            baseKeyPair:baseKeyPair];
        [[KStorageManager sharedManager] setObject:preKey forKey:preKey.signedPreKeyId inCollection:kOurPreKeyCollection];
        [preKeys addObject:[self base64EncodedPreKeyDictionary:preKey]];
        index++;
    }
    return [[NSArray alloc] initWithArray:preKeys];
}

- (NSDictionary *)base64EncodedPreKeyDictionary:(PreKey *)preKey {
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
