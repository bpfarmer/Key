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
#import "RootChain.h"
#import "MessageKey.h"
#import "KOutgoingObject.h"
#import "CollapsingFutures.h"

@implementation FreeKey

+ (void)sendEncryptableObject:(KDatabaseObject *)encryptableObject recipients:(NSArray *)recipients {
    //KOutgoingObject *outgoingObject = [[KOutgoingObject alloc] initWithObject:encryptableObject recipients:recipients];
    //[outgoingObject save];
    
    dispatch_queue_t queue = dispatch_queue_create([kEncryptObjectQueue cStringUsingEncoding:NSASCIIStringEncoding], NULL);

    [recipients enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        dispatch_async(queue, ^{
            NSLog(@"RECIPIENT ID PROVIDED: %@", obj);
            KUser *localUser = [KAccountManager sharedManager].user;
            KUser *remoteUser = [KUser findById:obj];
            NSLog(@"LOCAL USER: %@, REMOTE USER: %@", localUser, remoteUser);
            if(!remoteUser) {
                TOCFuture *futureUser = [KUser asyncRetrieveWithUniqueId:obj];
                [futureUser thenDo:^(KUser *retrievedUser) {
                    TOCFuture *futureSession = [[FreeKeySessionManager sharedManager] sessionWithLocalUser:localUser remoteUser:remoteUser];
                    [futureSession thenDo:^(Session *session) {
                        EncryptedMessage *encryptedMessage = [self encryptObject:encryptableObject session:session];
                        [[FreeKeyNetworkManager sharedManager] sendEncryptedMessage:encryptedMessage];
                    }];
                }];
            }
            TOCFuture *futureSession = [[FreeKeySessionManager sharedManager] sessionWithLocalUser:localUser remoteUser:remoteUser];
            [futureSession thenDo:^(Session *session) {
                EncryptedMessage *encryptedMessage = [self encryptObject:encryptableObject session:session];
                [[FreeKeyNetworkManager sharedManager] sendEncryptedMessage:encryptedMessage];
            }];
        });
    }];
}

+ (void)decryptAndSaveEncryptedMessage:(EncryptedMessage *)encryptedMessage {
    dispatch_queue_t queue = dispatch_queue_create([kEncryptObjectQueue cStringUsingEncoding:NSASCIIStringEncoding], NULL);
    
    dispatch_async(queue, ^{
        KUser *localUser = [KAccountManager sharedManager].user;
        KUser *remoteUser = [KUser findById:encryptedMessage.senderId];
        if(remoteUser) {
            TOCFuture *futureSession = [[FreeKeySessionManager sharedManager] sessionWithLocalUser:localUser remoteUser:remoteUser];
            [futureSession thenDo:^(Session *session) {
                KDatabaseObject *decryptedObject = (KDatabaseObject *)[self decryptEncryptedMessage:encryptedMessage session:session];
                [decryptedObject save];
            }];
        }else {
            TOCFuture *futureUser = [KUser asyncRetrieveWithUniqueId:encryptedMessage.senderId];
            [futureUser thenDo:^(KUser *remoteUser) {
                TOCFuture *futureSession = [[FreeKeySessionManager sharedManager] sessionWithLocalUser:localUser remoteUser:remoteUser];
                [futureSession thenDo:^(Session *session) {
                    KDatabaseObject *decryptedObject = (KDatabaseObject *)[self decryptEncryptedMessage:encryptedMessage session:session];
                    [decryptedObject save];
                }];
            }];
        }
    });
}

#pragma mark - Encryption and Decryption Wrappers
+ (EncryptedMessage *)encryptObject:(id<KEncryptable>)object session:(Session *)session {
    NSData *serializedObject = [NSKeyedArchiver archivedDataWithRootObject:object];
    EncryptedMessage *encryptedMessage = [session encryptMessage:serializedObject];
    KUser *localUser = [KAccountManager sharedManager].user;
    [encryptedMessage addMetadataFromLocalUserId:localUser.uniqueId toRemoteUserId:session.receiverId];
    [session save];
    return encryptedMessage;
}

+ (KDatabaseObject *)decryptEncryptedMessage:(EncryptedMessage *)encryptedMessage session:(Session *)session {
    NSData *decryptedData = [session decryptMessage:encryptedMessage];
    [session save];
    return [NSKeyedUnarchiver unarchiveObjectWithData:decryptedData];
}

@end
