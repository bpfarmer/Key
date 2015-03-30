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
#import "ChainKey.h"
#import "MessageKey.h"

@implementation FreeKey

#pragma mark - Encryption and Decryption Wrappers
+ (EncryptedMessage *)encryptObject:(id<KEncryptable>)object session:(Session *)session {
    NSData *serializedObject = [NSKeyedArchiver archivedDataWithRootObject:object];
    EncryptedMessage *encryptedMessage = [session encryptMessage:serializedObject];
    return encryptedMessage;
}

+ (id <KEncryptable>)decryptEncryptedMessage:(EncryptedMessage *)encryptedMessage session:(Session *)session {
    NSData *decryptedData = [session decryptMessage:encryptedMessage];
    return [NSKeyedUnarchiver unarchiveObjectWithData:decryptedData];
}

@end
