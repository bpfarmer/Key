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

@implementation FreeKeyNetworkManager

+ (instancetype)sharedManager {
    static FreeKeyNetworkManager *sharedMyManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (void)pollFeedForLocalUser:(KUser *)localUser {
    dispatch_queue_t queue = dispatch_queue_create([kHTTPRequestQueue cStringUsingEncoding:NSASCIIStringEncoding], NULL);
    dispatch_async(queue, ^{
        [[HttpManager sharedManager] getObjectsWithRemoteAlias:kFeedRemoteAlias parameters:@{@"uniqueId" : localUser.uniqueId}];
    });
}

- (void)receiveRemoteFeed:(NSDictionary *)objects withLocalUser:(KUser *)localUser {
    dispatch_queue_t queue = dispatch_queue_create([kHTTPResponseQueue cStringUsingEncoding:NSASCIIStringEncoding], NULL);
    dispatch_async(queue, ^{
        if(objects[kPreKeyExchangeRemoteAlias]) {
            NSArray *preKeyExchanges;
            if([objects[kPreKeyExchangeRemoteAlias] isKindOfClass:[NSDictionary class]]) {
                preKeyExchanges = [[NSArray alloc] initWithObjects:objects[kPreKeyExchangeRemoteAlias], nil];
            }else {
                preKeyExchanges = (NSArray *)objects[kPreKeyExchangeRemoteAlias];
            }
            [preKeyExchanges enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSDictionary *pkeDict = (NSDictionary *)obj;
                if(pkeDict) {
                    [self createPreKeyExchangeFromRemoteDictionary:pkeDict];
                }
            }];
        }
        if(objects[kEncryptedMessageRemoteAlias]) {
            NSArray *encryptedMessages;
            if([objects[kEncryptedMessageRemoteAlias] isKindOfClass:[NSDictionary class]]) {
                encryptedMessages = [[NSArray alloc] initWithObjects:objects[kEncryptedMessageRemoteAlias], nil];
            }else {
                encryptedMessages = (NSArray *)objects[kEncryptedMessageRemoteAlias];
            }
            [encryptedMessages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSDictionary *emDictionary = (NSDictionary *)obj;
                if(emDictionary) {
                    EncryptedMessage *message = [self createEncryptedMessageFromRemoteDictionary:emDictionary];
                    [self enqueueDecryptableMessage:message toLocalUser:localUser];
                }
            }];
        }
    });
}

- (PreKey *)createPreKeyFromRemoteDictionary:(NSDictionary *)dictionary {
    NSArray *remoteKeys = [PreKey remoteKeys];
    PreKey *preKey = [[PreKey alloc] initWithUserId:dictionary[remoteKeys[0]]
                                           deviceId:dictionary[remoteKeys[1]]
                                     signedPreKeyId:dictionary[remoteKeys[2]]
                                 signedPreKeyPublic:dictionary[remoteKeys[3]]
                              signedPreKeySignature:dictionary[remoteKeys[4]]
                                        identityKey:dictionary[remoteKeys[5]]
                                        baseKeyPair:nil];
    
    // TODO: unify how we're calling collection methods
    if(preKey) {
        KUser *remoteUser = [[KStorageManager sharedManager] objectForKey:preKey.userId inCollection:[KUser collection]];
        if(remoteUser) {
            KUser *currentUser = [KAccountManager sharedManager].user;
            Session *session = [[FreeKeySessionManager sharedManager] processNewPreKey:preKey
                                                                             localUser:currentUser
                                                                            remoteUser:remoteUser];
            if(session) {
                [[KStorageManager sharedManager] setObject:session forKey:remoteUser.uniqueId inCollection:kSessionCollection];
            }else {
                // TODO: throw invalid PreKey error
            }
        }else {
            [[HttpManager sharedManager] enqueueGetWithRemoteAlias:kUserRemoteAlias parameters:@{@"userId" : preKey.userId}];
        }
    }else {
        // TODO: throw invalid PreKey error
    }
    return preKey;
}

- (PreKeyExchange *)createPreKeyExchangeFromRemoteDictionary:(NSDictionary *)dictionary {
    NSArray *remoteKeys = [PreKeyExchange remoteKeys];
    PreKeyExchange *preKeyExchange =
    [[PreKeyExchange alloc]  initWithSenderId:dictionary[remoteKeys[0]]
                                   receiverId:dictionary[remoteKeys[1]]
                         signedTargetPreKeyId:dictionary[remoteKeys[2]]
                            sentSignedBaseKey:dictionary[remoteKeys[3]]
                      senderIdentityPublicKey:dictionary[remoteKeys[4]]
                    receiverIdentityPublicKey:dictionary[remoteKeys[5]]
                             baseKeySignature:dictionary[remoteKeys[6]]];
    
    if(preKeyExchange) {
        KUser *remoteUser = (KUser *)[[KStorageManager sharedManager] objectForKey:preKeyExchange.senderId
                                                                      inCollection:[KUser collection]];
        if(remoteUser) {
            KUser *currentUser = [KAccountManager sharedManager].user;
            Session *session = [[FreeKeySessionManager sharedManager] processNewPreKeyExchange:preKeyExchange
                                                                                     localUser:currentUser
                                                                                    remoteUser:remoteUser];
            if(session) {
                [[KStorageManager sharedManager] setObject:session forKey:remoteUser.uniqueId inCollection:kSessionCollection];
            }else {
                // TODO: throw invalid PreKeyExchange error
            }
        }
    }
    return preKeyExchange;
}

- (void)enqueueEncryptableObject:(id <KEncryptable>)object localUser:(KUser *)localUser remoteUser:(KUser *)remoteUser {
    dispatch_queue_t queue = dispatch_queue_create([kEncryptObjectQueue cStringUsingEncoding:NSASCIIStringEncoding], NULL);
    dispatch_async(queue, ^{
        [FreeKey sendObject:object fromLocalUser:localUser toRemoteUser:remoteUser];
    });
}

- (void)enqueueDecryptableMessage:(EncryptedMessage *)encryptedMessage toLocalUser:(KUser *)localUser {
    dispatch_queue_t queue = dispatch_queue_create([kDecryptObjectQueue cStringUsingEncoding:NSASCIIStringEncoding], NULL);
    dispatch_async(queue, ^{
        KUser *remoteUser = (KUser *)[[KStorageManager sharedManager] objectForKey:encryptedMessage.senderId
                                                                      inCollection:[KUser collection]];
        if(remoteUser) {
            [FreeKey receiveEncryptedMessage:encryptedMessage localUser:localUser remoteUser:remoteUser];
        }else {
            [KUser retrieveRemoteUserWithUserId:encryptedMessage.senderId];
        }
    });
}

- (EncryptedMessage *)createEncryptedMessageFromRemoteDictionary:(NSDictionary *)dictionary {
    NSArray *remoteKeys = [EncryptedMessage remoteKeys];
    NSNumber *index = (NSNumber *)dictionary[remoteKeys[4]];
    NSNumber *previousIndex = (NSNumber *)dictionary[remoteKeys[5]];
    EncryptedMessage *encryptedMessage =
    [[EncryptedMessage alloc] initWithSenderRatchetKey:dictionary[remoteKeys[0]]
                                              senderId:dictionary[remoteKeys[2]]
                                            receiverId:dictionary[remoteKeys[1]]
                                        serializedData:dictionary[remoteKeys[3]]
                                                 index:[index intValue]
                                         previousIndex:[previousIndex intValue]];
    
    NSLog(@"ENCRYPTED MESSAGE INDEX: %d", encryptedMessage.index);
    NSLog(@"ENCRYPTED MESSAGE SERIALIZED DATA: %@", encryptedMessage.serializedData);
    
    NSString *uniqueMessageId = [NSString stringWithFormat:@"%@_%f_%@",
                                 dictionary[encryptedMessage],
                                 [[NSDate date] timeIntervalSince1970],
                                 index];
    
    [[KStorageManager sharedManager]setObject:encryptedMessage forKey:uniqueMessageId inCollection:kEncryptedMessageCollection];
    return encryptedMessage;
}

- (void)enqueueGetRequestWithRemoteAlias:(NSString *)remoteAlias parameters:(NSDictionary *)parameters {
    dispatch_queue_t queue = dispatch_queue_create([kHTTPRequestQueue cStringUsingEncoding:NSASCIIStringEncoding], NULL);
    dispatch_async(queue, ^{
        [[HttpManager sharedManager] getObjectsWithRemoteAlias:remoteAlias parameters:parameters];
    });
}

- (void)receiveRemoteObject:(NSDictionary *)dictionary ofType:(NSString *)type {
    if([type isEqualToString:kPreKeyExchangeRemoteAlias]) {
        [self createPreKeyExchangeFromRemoteDictionary:dictionary[kPreKeyExchangeRemoteAlias]];
    }else if([type isEqualToString:kPreKeyRemoteAlias]) {
        [self createPreKeyFromRemoteDictionary:dictionary[kPreKeyRemoteAlias]];
    }else if([type isEqualToString:kEncryptedMessageRemoteAlias]) {
        [self createEncryptedMessageFromRemoteDictionary:dictionary[kEncryptedMessageRemoteAlias]];
    }else {
        Class <KSendable> objectClass = NSClassFromString([self getClassNameFromType:type]);
        [objectClass createFromRemoteDictionary:dictionary];
    }
}

- (NSString *)getClassNameFromType:(NSString *)type {
    NSDictionary *classNames = @{kUserRemoteAlias : @"KUser"};
    return classNames[type];
}

- (void)sendPreKeysToServer:(NSArray *)preKeys {
    [[HttpManager sharedManager] batchPut:kPreKeyRemoteAlias objects:preKeys];
}

- (void)sendPreKeyExchange:(PreKeyExchange *)preKeyExchange toRemoteUser:(KUser *)remoteUser {
    KUser *currentUser = [KAccountManager sharedManager].user;
    [preKeyExchange setSenderId:currentUser.uniqueId];
    [[HttpManager sharedManager] enqueueSendableObject:preKeyExchange];
}

- (void)getPreKeyWithRemoteUser:(KUser *)remoteUser {
    NSDictionary *parameters = @{@"userId" : remoteUser.uniqueId};
    [[HttpManager sharedManager] getObjectsWithRemoteAlias:kPreKeyRemoteAlias parameters:parameters];
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
