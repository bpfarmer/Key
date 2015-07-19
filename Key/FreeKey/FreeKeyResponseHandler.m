//
//  FreeKeyResponseHandler.m
//  Key
//
//  Created by Brendan Farmer on 3/28/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "FreeKeyResponseHandler.h"
#import "PreKey.h"
#import "PreKeyExchange.h"
#import "KStorageManager.h"
#import "HttpManager.h"
#import "FreeKey.h"
#import "FreeKeyNetworkManager.h"
#import "EncryptedMessage.h"

@implementation FreeKeyResponseHandler

+ (PreKey *)createPreKeyFromRemoteDictionary:(NSDictionary *)dictionary {
    NSArray *remoteKeys = [PreKey remoteKeys];
    PreKey *preKey = [[PreKey alloc] initWithUserId:dictionary[remoteKeys[0]]
                                           deviceId:dictionary[remoteKeys[1]]
                                     signedPreKeyId:dictionary[remoteKeys[2]]
                                 signedPreKeyPublic:dictionary[remoteKeys[3]]
                              signedPreKeySignature:dictionary[remoteKeys[4]]
                                        identityKey:dictionary[remoteKeys[5]]
                                        baseKeyPair:nil];
    
    [preKey save];
    return preKey;
}

+ (PreKeyExchange *)createPreKeyExchangeFromRemoteDictionary:(NSDictionary *)dictionary {
    NSArray *remoteKeys = [PreKeyExchange remoteKeys];
    PreKeyExchange *preKeyExchange =
    [[PreKeyExchange alloc]  initWithSenderId:dictionary[remoteKeys[0]]
                                   receiverId:dictionary[remoteKeys[1]]
                               senderDeviceId:dictionary[remoteKeys[2]]
                         signedTargetPreKeyId:dictionary[remoteKeys[2]]
                            sentSignedBaseKey:dictionary[remoteKeys[3]]
                      senderIdentityPublicKey:dictionary[remoteKeys[4]]
                    receiverIdentityPublicKey:dictionary[remoteKeys[5]]
                             baseKeySignature:dictionary[remoteKeys[6]]];
    
    [preKeyExchange save];
    return preKeyExchange;
}

+ (EncryptedMessage *)createEncryptedMessageFromRemoteDictionary:(NSDictionary *)dictionary {
    NSArray *remoteKeys = [EncryptedMessage remoteKeys];
    NSNumber *index = [[NSNumber alloc] initWithInt:[dictionary[remoteKeys[4]] intValue]];
    NSNumber *previousIndex = [[NSNumber alloc] initWithInt:[dictionary[remoteKeys[5]] intValue]];
    EncryptedMessage *encryptedMessage = [[EncryptedMessage alloc] initWithSenderRatchetKey:dictionary[remoteKeys[0]]
                                                                                   senderId:dictionary[remoteKeys[2]]
                                                                                 receiverId:dictionary[remoteKeys[1]]
                                                                             serializedData:dictionary[remoteKeys[3]]
                                                                                      index:index
                                                                              previousIndex:previousIndex];
    
    [encryptedMessage save];
    return encryptedMessage;
}

@end
