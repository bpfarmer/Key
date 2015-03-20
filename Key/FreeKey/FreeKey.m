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

@implementation FreeKey

+ (instancetype)sharedManager {
    static FreeKey *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

#pragma  mark - PreKey Generation
- (NSArray *)generatePreKeysForUser:(KUser *)user {
    int index = 0;
    NSMutableArray *preKeys = [[NSMutableArray alloc] init];
    while(index < 100) {
        ECKeyPair *baseKeyPair = [Curve25519 generateKeyPair];
        NSString *uniquePreKeyId = [NSString stringWithFormat:@"%@_%f_%d", user.uniqueId, [[NSDate date] timeIntervalSince1970], index];
        NSData *preKeySignature = [Ed25519 sign:baseKeyPair.publicKey withKeyPair:user.identityKey.keyPair];
        PreKey *preKey = [[PreKey alloc] initWithUserId:user.uniqueId
                                                 deviceId:@"1"
                                           signedPreKeyId:uniquePreKeyId
                                       signedPreKeyPublic:baseKeyPair.publicKey
                                    signedPreKeySignature:preKeySignature
                                              identityKey:user.publicKey
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

- (void)sendPreKeysToServer:(NSArray *)preKeys {
    [[HttpManager sharedManager] batchPut:kPreKeyRemoteAlias objects:preKeys];
}

#pragma mark - Encryption and Decryption Wrappers
- (EncryptedMessage *)encryptObject:(id<KEncryptable>)object
                          localUser:(KUser *)localUser
                        recipientId:(NSString *)recipientId {
    Session *session = (Session *)[[KStorageManager sharedManager] objectForKey:recipientId
                                                                   inCollection:kSessionCollection];
    if(!session) {
        PreKeyExchange *preKeyExchange = (PreKeyExchange *)
            [[KStorageManager sharedManager] objectForKey:recipientId inCollection:kPreKeyExchangeCollection];
        if(preKeyExchange) {
            session = [self createSessionFromUser:localUser withPreKeyExchange:preKeyExchange];
        }else {
            PreKey *preKey = [self getPreKeyForUserId:recipientId];
            if(!preKey) {
                [self getRemotePreKeyForUserId:recipientId];
                return nil;
            }else {
                session = [self createSessionFromUser:localUser withPreKey:preKey];
            }
        }
    }
    NSData *serializedData = [NSKeyedArchiver archivedDataWithRootObject:object];
    EncryptedMessage *encryptedMessage = [session encryptMessage:serializedData];
    
    [[KStorageManager sharedManager] setObject:session forKey:recipientId inCollection:kSessionCollection];
    
    [encryptedMessage setSenderId:localUser.uniqueId];
    [encryptedMessage setReceiverId:recipientId];
    return encryptedMessage;
}

- (id <KEncryptable>)decryptEncryptedMessage:(EncryptedMessage *)encryptedMessage
                                    localUser:(KUser *)localUser
                                    senderId:(NSString *)senderId {
    
    Session *session = (Session *)[[KStorageManager sharedManager] objectForKey:senderId
                                                                   inCollection:kSessionCollection];
    if(!session) {
        PreKeyExchange *preKeyExchange = (PreKeyExchange *)[[KStorageManager sharedManager] objectForKey:senderId inCollection:kPreKeyExchangeCollection];
        
        if(preKeyExchange) {
            session = [self createSessionFromUser:localUser withPreKeyExchange:preKeyExchange];
        }
    }
    NSData *decryptedData = [session decryptMessage:encryptedMessage];
    
    [[KStorageManager sharedManager] setObject:session forKey:senderId inCollection:kSessionCollection];
    
    return [NSKeyedUnarchiver unarchiveObjectWithData:decryptedData];
}

#pragma mark - Session Generation
- (Session *)createSessionFromUser:(KUser *)localUser withPreKey:(PreKey *)preKey {
    Session *session = [[Session alloc] initWithReceiverId:preKey.userId identityKey:localUser.identityKey];
    PreKeyExchange *preKeyExchange = [session addPreKey:preKey];
    [preKeyExchange setSenderId:localUser.uniqueId];
    [self enqueueSendableObject:preKeyExchange];
    return session;
}

- (Session *)createSessionFromUser:(KUser *)localUser withPreKeyExchange:(PreKeyExchange *)preKeyExchange {
    Session *session  = [[Session alloc] initWithReceiverId:preKeyExchange.senderId identityKey:localUser.identityKey];
    PreKey *ourPreKey = [[KStorageManager sharedManager] objectForKey:preKeyExchange.signedTargetPreKeyId
                                                         inCollection:kOurPreKeyCollection];
    [session addOurPreKey:ourPreKey preKeyExchange:preKeyExchange];
    return session;
}

#pragma mark - Retrieving PreKeys for Remote Users
- (PreKey *)getPreKeyForUserId:(NSString *)userId {
    return (PreKey *)[[KStorageManager sharedManager] objectForKey:userId inCollection:kTheirPreKeyCollection];
}

- (void)getRemotePreKeyForUserId:(NSString *)userId {
    NSDictionary *parameters = @{@"userId" : userId};
    [[HttpManager sharedManager] getObjectsWithRemoteAlias:kPreKeyRemoteAlias parameters:parameters];
}

- (void)getRemoteUserWithUsername:(NSString *)username {
    NSDictionary *parameters = @{kUserRemoteAlias: @{@"username" : username}};
    [[HttpManager sharedManager] getObjectsWithRemoteAlias:kUserRemoteAlias parameters:parameters];
}

/* 
   Note: trying hard to keep all serialization and networking methods out of the main
   FreeKey classes. Not sure if this is a good idea.
*/

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
            for(NSDictionary *preKeyExchangeDictionary in objects[kPreKeyExchangeRemoteAlias]) {
                [self createPreKeyExchangeFromRemoteDictionary:preKeyExchangeDictionary];
            }
        }
        if(objects[kEncryptedMessageRemoteAlias]) {
            for(NSDictionary *encryptedMessageDictionary in objects[kEncryptedMessageRemoteAlias]) {
                EncryptedMessage *message = [self createEncryptedMessageFromRemoteDictionary:encryptedMessageDictionary];
                [self enqueueDecryptableObject:message toLocalUser:localUser];
            }
        }
    });
}

- (PreKey *)createPreKeyFromRemoteDictionary:(NSDictionary *)dictionary {
    NSArray *remoteKeys = [PreKey remoteKeys];
    PreKey *preKey = [[PreKey alloc] initWithUserId:dictionary[remoteKeys[0]]
                                           deviceId:dictionary[remoteKeys[1]]
                                     signedPreKeyId:dictionary[remoteKeys[2]]
                                 signedPreKeyPublic:[NSData dataWithBase64EncodedString:dictionary[remoteKeys[3]]]
                              signedPreKeySignature:[NSData dataWithBase64EncodedString:dictionary[remoteKeys[4]]]
                                        identityKey:[NSData dataWithBase64EncodedString:dictionary[remoteKeys[5]]]
                                        baseKeyPair:nil];
    
    return preKey;
}

- (PreKeyExchange *)createPreKeyExchangeFromRemoteDictionary:(NSDictionary *)dictionary {
    NSArray *remoteKeys = [PreKeyExchange remoteKeys];
    PreKeyExchange *preKeyExchange = [[PreKeyExchange alloc] initWithSenderId:dictionary[remoteKeys[0]]
                                                                   receiverId:dictionary[remoteKeys[1]]
                                                         signedTargetPreKeyId:dictionary[remoteKeys[2]]
                                                            sentSignedBaseKey:[NSData dataWithBase64EncodedString:dictionary[remoteKeys[3]]]
                                                      senderIdentityPublicKey:[NSData dataWithBase64EncodedString:dictionary[remoteKeys[4]]]
                                                    receiverIdentityPublicKey:[NSData dataWithBase64EncodedString:dictionary[remoteKeys[5]]]
                                                             baseKeySignature:[NSData dataWithBase64EncodedString:dictionary[remoteKeys[6]]]];
    return preKeyExchange;
}

- (EncryptedMessage *)createEncryptedMessageFromRemoteDictionary:(NSDictionary *)dictionary {
    NSArray *remoteKeys = [EncryptedMessage remoteKeys];
    NSNumber *index = (NSNumber *)dictionary[remoteKeys[3]];
    NSNumber *previousIndex = (NSNumber *)dictionary[remoteKeys[4]];
    EncryptedMessage *encryptedMessage =
    [[EncryptedMessage alloc] initWithSenderRatchetKey:[NSData dataWithBase64EncodedString:dictionary[remoteKeys[0]]]
                                            receiverId:dictionary[remoteKeys[1]]
                                        serializedData:[NSData dataWithBase64EncodedString:dictionary[remoteKeys[3]]]
                                                 index:[index intValue]
                                         previousIndex:[previousIndex intValue]];
    
    NSString *uniqueMessageId = [NSString stringWithFormat:@"%@_%f_%@",
                                 dictionary[encryptedMessage],
                                 [[NSDate date] timeIntervalSince1970],
                                 index];
    
    NSLog(@"SERIALIZED DATA: %@", encryptedMessage.serializedData);
    
    [[KStorageManager sharedManager]setObject:encryptedMessage forKey:uniqueMessageId inCollection:kEncryptedMessageCollection];
    
    return encryptedMessage;
}

- (void)enqueueEncryptableObject:(id<KEncryptable>)object fromUser:(KUser *)localUser toUserId:(NSString *)userId {
    dispatch_queue_t queue = dispatch_queue_create([kEncryptObjectQueue cStringUsingEncoding:NSASCIIStringEncoding], NULL);
    dispatch_async(queue, ^{
        EncryptedMessage *encryptedMessage = [self encryptObject:object localUser:localUser recipientId:userId];
        [self enqueueSendableObject:encryptedMessage];
    });
}

- (void)enqueueSendableObject:(id<KSendable>)object {
    dispatch_queue_t queue = dispatch_queue_create([kHTTPRequestQueue cStringUsingEncoding:NSASCIIStringEncoding], NULL);
    dispatch_async(queue, ^{
        [[HttpManager sharedManager] put:object];
    });
}

- (void)enqueueDecryptableObject:(EncryptedMessage *)message toLocalUser:(KUser *)localUser {
    dispatch_queue_t queue = dispatch_queue_create([kDecryptObjectQueue cStringUsingEncoding:NSASCIIStringEncoding], NULL);
    dispatch_async(queue, ^{
        KMessage *object = (KMessage *)[self decryptEncryptedMessage:message localUser:localUser senderId:message.senderId];
        NSLog(@"OBJECT ID: %@", object.body);
        [object save];
    });
}

- (void)enqueueGetRequestWithRemoteAlias:(NSString *)remoteAlias parameters:(NSDictionary *)parameters {
    dispatch_queue_t queue = dispatch_queue_create([kHTTPRequestQueue cStringUsingEncoding:NSASCIIStringEncoding], NULL);
    dispatch_async(queue, ^{
        [[HttpManager sharedManager] getObjectsWithRemoteAlias:remoteAlias parameters:parameters];
    });
}

@end
