//
//  PreKey+Serialize.m
//  Key
//
//  Created by Brendan Farmer on 3/14/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "PreKey+Serialize.h"
#import <25519/Curve25519.h>
#import <25519/Ed25519.h>

#define kCoderSignedPreKeyId @"signedPreKeyId"
#define kCoderSignedPreKeyPublic @"signedPreKeyPublic"
#define kCoderSignedPreKeySignature @"signedPreKeySignature"
#define kCoderIdentityKey @"identityKey"
#define kCoderUserId @"userId"
#define kCoderDeviceId @"deviceId"
#define kCoderBaseKeyPair @"baseKeyPair"


@implementation PreKey(Serialize)

+ (BOOL)supportsSecureCoding{
    return YES;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    return [self initWithUserId:[aDecoder decodeObjectOfClass:[NSString class] forKey:kCoderUserId]
                       deviceId:[aDecoder decodeObjectOfClass:[NSString class] forKey:kCoderDeviceId]
                 signedPreKeyId:[aDecoder decodeObjectOfClass:[NSString class] forKey:kCoderSignedPreKeyId]
             signedPreKeyPublic:[aDecoder decodeObjectOfClass:[NSData class] forKey:kCoderSignedPreKeyPublic]
          signedPreKeySignature:[aDecoder decodeObjectOfClass:[NSData class] forKey:kCoderSignedPreKeySignature]
                    identityKey:[aDecoder decodeObjectOfClass:[NSData class] forKey:kCoderIdentityKey]
                    baseKeyPair:[aDecoder decodeObjectOfClass:[ECKeyPair class] forKey:kCoderBaseKeyPair]];

}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.userId forKey:kCoderUserId];
    [aCoder encodeObject:self.deviceId forKey:kCoderDeviceId];
    [aCoder encodeObject:self.signedPreKeyPublic forKey:kCoderSignedPreKeyPublic];
    [aCoder encodeObject:self.signedPreKeyId forKey:kCoderSignedPreKeyId];
    [aCoder encodeObject:self.signedPreKeySignature forKey:kCoderSignedPreKeySignature];
    [aCoder encodeObject:self.identityKey forKey:kCoderIdentityKey];
    [aCoder encodeObject:self.baseKeyPair forKey:kCoderBaseKeyPair];
}

@end
