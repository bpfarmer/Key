//
//  Session+Serialize.m
//  Key
//
//  Created by Brendan Farmer on 3/14/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "Session+Serialize.h"
#import "PreKey.h"
#import "IdentityKey.h"
#import "RootChain.h"

#define kCoderSenderId @"senderId"
#define kCoderReceiverId @"receiverId"
#define kCoderPreKey @"preKey"
#define kCoderBaseKeyPublic @"baseKeyPublic"
#define kCoderSenderIdentityKey @"senderIdentityKey"
#define kCoderReceiverIdentityPublicKey @"receiverIdentityKey"
#define kCoderSenderRootChain @"senderRootChain"
#define kCoderReceiverRootChain @"receiverRootChain"
#define kCoderPreviousIndex @"previousIndex"
#define kCoderPreviousSessionStates @"previousSessionStates"

@implementation Session(Serialize)

+ (BOOL)hasUniqueId {
    return NO;
}

@end
