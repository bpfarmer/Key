//
//  PreKeyExchange+Serialize.m
//  Key
//
//  Created by Brendan Farmer on 3/14/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "PreKeyExchange+Serialize.h"

#define kCoderSenderId @"senderId"
#define kCoderReceiverId @"receiverId"
#define kCoderSignedTargetPreKeyId @"signedTargetPreKeyId"
#define kCoderSentSignedBaseKey @"sentSignedBaseKey"
#define kCoderSenderIdentityPublicKey @"senderIdentityPublicKey"
#define kCoderReceiverIdentityPublicKey @"receiverIdentityPublicKey"
#define kCoderBaseKeySignature @"baseKeySignature"


@implementation PreKeyExchange(Serialize)

+ (BOOL)supportsSecureCoding{
    return YES;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    return [self initWithSenderId:[aDecoder decodeObjectOfClass:[NSString class] forKey:kCoderSenderId]
                       receiverId:[aDecoder decodeObjectOfClass:[NSString class] forKey:kCoderReceiverId]
             signedTargetPreKeyId:[aDecoder decodeObjectOfClass:[NSString class] forKey:kCoderSignedTargetPreKeyId]
                sentSignedBaseKey:[aDecoder decodeObjectOfClass:[NSData class] forKey:kCoderSentSignedBaseKey]
          senderIdentityPublicKey:[aDecoder decodeObjectOfClass:[NSData class] forKey:kCoderSenderIdentityPublicKey]
        receiverIdentityPublicKey:[aDecoder decodeObjectOfClass:[NSData class] forKey:kCoderReceiverIdentityPublicKey]
                 baseKeySignature:[aDecoder decodeObjectOfClass:[NSData class] forKey:kCoderBaseKeySignature]];
    
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.senderId forKey:kCoderSenderId];
    [aCoder encodeObject:self.receiverId forKey:kCoderReceiverId];
    [aCoder encodeObject:self.signedTargetPreKeyId forKey:kCoderSignedTargetPreKeyId];
    [aCoder encodeObject:self.sentSignedBaseKey forKey:kCoderSentSignedBaseKey];
    [aCoder encodeObject:self.senderIdentityPublicKey forKey:kCoderSenderIdentityPublicKey];
    [aCoder encodeObject:self.receiverIdentityPublicKey forKey:kCoderReceiverIdentityPublicKey];
    [aCoder encodeObject:self.baseKeySignature forKey:kCoderBaseKeySignature];
}

@end
