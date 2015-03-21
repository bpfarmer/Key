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
                                 signedPreKeyPublic:dictionary[remoteKeys[3]]
                              signedPreKeySignature:dictionary[remoteKeys[4]]
                                        identityKey:dictionary[remoteKeys[5]]
                                        baseKeyPair:nil];
    
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
    return preKeyExchange;
}

- (void)enqueueEncryptableObject:(id <KEncryptable>)object localUser:(KUser *)localUser remoteUser:(KUser *)remoteUser {
    dispatch_queue_t queue = dispatch_queue_create([kEncryptObjectQueue cStringUsingEncoding:NSASCIIStringEncoding], NULL);
    dispatch_async(queue, ^{
        Session *session = [[FreeKeySessionManager sharedManager] sessionWithLocalUser:localUser remoteUser:remoteUser];
        if(session) {
            EncryptedMessage *encryptedMessage = [FreeKey encryptObject:object session:session];
            [[HttpManager sharedManager] enqueueSendableObject:encryptedMessage];
        }else {
            session = [[FreeKeySessionManager sharedManager] createSessionWithLocalUser:localUser remoteUser:remoteUser];
            if(!session) {
                
            }
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
    
    NSString *uniqueMessageId = [NSString stringWithFormat:@"%@_%f_%@",
                                 dictionary[encryptedMessage],
                                 [[NSDate date] timeIntervalSince1970],
                                 index];
    
    [[KStorageManager sharedManager]setObject:encryptedMessage forKey:uniqueMessageId inCollection:kEncryptedMessageCollection];
    
    return encryptedMessage;
}

- (void)enqueueDecryptableObject:(EncryptedMessage *)message toLocalUser:(KUser *)localUser {
    dispatch_queue_t queue = dispatch_queue_create([kDecryptObjectQueue cStringUsingEncoding:NSASCIIStringEncoding], NULL);
    dispatch_async(queue, ^{
        //KMessage *object = (KMessage *)[self decryptEncryptedMessage:message localUser:localUser senderId:message.senderId];
        //[object save];
    });
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

- (void)getPreKeyWithRemoteUser:(KUser *)remoteUser {
    NSDictionary *parameters = @{@"userId" : remoteUser.uniqueId};
    [[HttpManager sharedManager] getObjectsWithRemoteAlias:kPreKeyRemoteAlias parameters:parameters];
}


@end
