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

+ (BOOL)supportsSecureCoding{
    return YES;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    return [self initWithSenderId:[aDecoder decodeObjectOfClass:[NSString class] forKey:kCoderSenderId]
                       receiverId:[aDecoder decodeObjectOfClass:[NSString class] forKey:kCoderReceiverId]
                           preKey:[aDecoder decodeObjectOfClass:[PreKey class] forKey:kCoderPreKey]
                    baseKeyPublic:[aDecoder decodeObjectOfClass:[NSData class] forKey:kCoderBaseKeyPublic]
                senderIdentityKey:[aDecoder decodeObjectOfClass:[IdentityKey class] forKey:kCoderSenderIdentityKey]
        receiverIdentityPublicKey:[aDecoder decodeObjectOfClass:[NSData class] forKey:kCoderReceiverIdentityPublicKey]
                  senderRootChain:[aDecoder decodeObjectOfClass:[RootChain class] forKey:kCoderSenderRootChain]
                receiverRootChain:[aDecoder decodeObjectOfClass:[RootChain class] forKey:kCoderReceiverRootChain]
                    previousIndex:[aDecoder decodeIntForKey:kCoderPreviousIndex]
            previousSessionStates:[aDecoder decodeObjectOfClass:[NSDictionary class] forKey:kCoderPreviousSessionStates]];
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.senderId forKey:kCoderSenderId];
    [aCoder encodeObject:self.receiverId forKey:kCoderReceiverId];
    [aCoder encodeObject:self.preKey forKey:kCoderPreKey];
    [aCoder encodeObject:self.baseKeyPublic forKey:kCoderBaseKeyPublic];
    [aCoder encodeObject:self.senderIdentityKey forKey:kCoderSenderIdentityKey];
    [aCoder encodeObject:self.receiverIdentityPublicKey forKey:kCoderReceiverIdentityPublicKey];
    [aCoder encodeObject:self.senderRootChain forKey:kCoderSenderRootChain];
    [aCoder encodeObject:self.receiverRootChain forKey:kCoderReceiverRootChain];
    [aCoder encodeInt:self.previousIndex forKey:kCoderPreviousIndex];
    [aCoder encodeObject:self.previousSessionStates forKey:kCoderPreviousSessionStates];
}

+ (BOOL)hasUniqueId {
    return NO;
}

@end
