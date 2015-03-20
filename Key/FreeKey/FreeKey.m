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
#import "FreeKeyNetworkManager.h"

@implementation FreeKey

#pragma mark - Encryption and Decryption Wrappers
+ (EncryptedMessage *)encryptObject:(id<KEncryptable>)object session:(Session *)session {
    NSData *serializedObject = [NSKeyedArchiver archivedDataWithRootObject:object];
    return [session encryptMessage:serializedObject];
}

+ (id <KEncryptable>)decryptEncryptedMessage:(EncryptedMessage *)encryptedMessage session:(Session *)session {
    NSData *decryptedData = [session decryptMessage:encryptedMessage];
    return [NSKeyedUnarchiver unarchiveObjectWithData:decryptedData];
}

+ (void)sendObject:(id <KEncryptable>)object fromLocalUser:(KUser *)localUser toRemoteUser:(KUser *)remoteUser {
    Session *session = [self getOrCreateSessionWithLocalUser:localUser remoteUser:remoteUser];
    if(session) {
        EncryptedMessage *encryptedMessage = [self encryptObject:object session:session];
        [encryptedMessage addMetadataFromLocalUserId:localUser.uniqueId toRemoteUserId:remoteUser.uniqueId];
        [[HttpManager sharedManager] enqueueSendableObject:encryptedMessage];
    }
}

+ (void)receiveEncryptedMessage:(EncryptedMessage *)encryptedMessage
                 fromRemoteUser:(KUser *)remoteUser
                    toLocalUser:(KUser *)localUser {
    Session *session = [self getOrCreateSessionWithLocalUser:localUser remoteUser:remoteUser];
    if(session) {
        id <KEncryptable> object = [self decryptEncryptedMessage:encryptedMessage session:session];
        [[KStorageManager sharedManager] setObject:object forKey:object.uniqueId inCollection:[object collection]];
    }
    
}

+ (Session *)getOrCreateSessionWithLocalUser:(KUser *)localUser remoteUser:(KUser *)remoteUser {
    Session *session = [[FreeKeySessionManager sharedManager] sessionWithLocalUser:localUser remoteUser:remoteUser];
    if(session) return session;
    return [[FreeKeySessionManager sharedManager] createSessionWithLocalUser:localUser remoteUser:remoteUser];
}

@end
