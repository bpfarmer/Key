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
        [[KStorageManager sharedManager] setObject:preKey forKey:preKey.signedPreKeyId inCollection:kPreKeyCollection];
        [preKeys addObject:[preKey dictionaryWithValuesForKeys:[preKey keysToSend]]];
        index++;
    }
    return [[NSArray alloc] initWithArray:preKeys];
}

- (void)sendPreKeysToServer:(NSArray *)preKeys {
    [[HttpManager sharedManager] batchPut:kPreKeyRemoteAlias objects:preKeys];
}

#pragma mark - Encryption and Decryption Queue

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
    return [session encryptMessage:serializedData];
}

- (id <KEncryptable>)decryptEncryptedMessage:(EncryptedMessage *)encryptedMessage
                                    localUser:(KUser *)localUser
                                    senderId:(NSString *)senderId {
    
    Session *session = (Session *)[[KStorageManager sharedManager] objectForKey:senderId
                                                                   inCollection:kSessionCollection];
    if(!session) {
        PreKeyExchange *preKeyExchange = (PreKeyExchange *)[[KStorageManager sharedManager] objectForKey:senderId inCollection:kPreKeyExchangeCollection];
        
        session = [self createSessionFromUser:localUser withPreKeyExchange:preKeyExchange];
    }
    NSData *decryptedData = [session decryptMessage:encryptedMessage];
    return [NSKeyedUnarchiver unarchiveObjectWithData:decryptedData];
}

#pragma mark - Session Generation
- (Session *)createSessionFromUser:(KUser *)localUser withPreKey:(PreKey *)preKey {
    Session *session = [[Session alloc] initWithReceiverId:preKey.userId identityKey:localUser.identityKey];
    [session addPreKey:preKey];
    return session;
}

- (Session *)createSessionFromUser:(KUser *)localUser withPreKeyExchange:(PreKeyExchange *)preKeyExchange {
    Session *session  = [[Session alloc] initWithReceiverId:preKeyExchange.senderId identityKey:localUser.identityKey];
    PreKey *ourPreKey = [[KStorageManager sharedManager] objectForKey:preKeyExchange.signedTargetPreKeyId
                                                         inCollection:kPreKeyCollection];
    [session addOurPreKey:ourPreKey preKeyExchange:preKeyExchange];
    return session;
}

#pragma mark - Retrieving PreKeys for Remote Users
- (PreKey *)getPreKeyForUserId:(NSString *)userId {
    return (PreKey *)[[KStorageManager sharedManager] objectForKey:userId inCollection:kPreKeyCollection];
}

- (void)getRemotePreKeyForUserId:(NSString *)userId {
    NSDictionary *parameters = @{@"userId" : userId};
    [[HttpManager sharedManager] getObjectsWithRemoteAlias:kPreKeyRemoteAlias parameters:parameters];
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
        Class <KSendable> objectClass = NSClassFromString(type);
        [objectClass createFromRemoteDictionary:dictionary];
    }
}

- (void)receiveRemoteFeed:(NSDictionary *)objects {
    if(objects[kPreKeyExchangeRemoteAlias]) {
        for(NSDictionary *preKeyExchangeDictionary in objects[kPreKeyExchangeRemoteAlias]) {
            [self createPreKeyExchangeFromRemoteDictionary:preKeyExchangeDictionary];
        }
    }
    if(objects[kEncryptedMessageRemoteAlias]) {
        for(NSDictionary *encryptedMessageDictionary in objects[kEncryptedMessageRemoteAlias]) {
            [self createEncryptedMessageFromRemoteDictionary:encryptedMessageDictionary];
        }
    }
    
}

- (void)createPreKeyFromRemoteDictionary:(NSDictionary *)dictionary {
    NSArray *remoteKeys = [PreKey remoteKeys];
    PreKey *preKey = [[PreKey alloc] initWithUserId:dictionary[remoteKeys[0]]
                                           deviceId:dictionary[remoteKeys[1]]
                                     signedPreKeyId:dictionary[remoteKeys[2]]
                                 signedPreKeyPublic:dictionary[remoteKeys[3]]
                              signedPreKeySignature:dictionary[remoteKeys[4]]
                                        identityKey:dictionary[remoteKeys[5]]
                                        baseKeyPair:nil];
    
    [[KStorageManager sharedManager] setObject:preKey
                                        forKey:preKey.userId
                                  inCollection:kPreKeyCollection];
}

- (void)createPreKeyExchangeFromRemoteDictionary:(NSDictionary *)dictionary {
    NSArray *remoteKeys = [PreKeyExchange remoteKeys];
    PreKeyExchange *preKeyExchange = [[PreKeyExchange alloc] initWithSenderId:dictionary[remoteKeys[0]]
                                                                   receiverId:dictionary[remoteKeys[1]]
                                                         signedTargetPreKeyId:dictionary[remoteKeys[2]]
                                                            sentSignedBaseKey:dictionary[remoteKeys[3]]
                                                      senderIdentityPublicKey:dictionary[remoteKeys[4]]
                                                    receiverIdentityPublicKey:dictionary[remoteKeys[5]]
                                                             baseKeySignature:dictionary[remoteKeys[6]]];
    [[KStorageManager sharedManager] setObject:preKeyExchange
                                        forKey:preKeyExchange.signedTargetPreKeyId
                                  inCollection:kPreKeyExchangeCollection];
}

- (void)createEncryptedMessageFromRemoteDictionary:(NSDictionary *)dictionary {
    NSArray *remoteKeys = [EncryptedMessage remoteKeys];
    NSNumber *index = (NSNumber *)dictionary[remoteKeys[4]];
    NSNumber *previousIndex = (NSNumber *)dictionary[remoteKeys[5]];
    EncryptedMessage *encryptedMessage = [[EncryptedMessage alloc] initWithSenderRatchetKey:dictionary[remoteKeys[1]]
                                                                                 receiverId:dictionary[remoteKeys[2]]
                                                                             serializedData:dictionary[remoteKeys[3]]
                                                                                      index:[index intValue]
                                                                              previousIndex:[previousIndex intValue]];
    
    NSString *uniqueMessageId = [NSString stringWithFormat:@"%@_%f_%@",
                                 dictionary[encryptedMessage],
                                 [[NSDate date] timeIntervalSince1970],
                                 index];

    [[KStorageManager sharedManager] setObject:encryptedMessage
                                        forKey:uniqueMessageId
                                  inCollection:kEncryptedMessageCollection];
}

@end
