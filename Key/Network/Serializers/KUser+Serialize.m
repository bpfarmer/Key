//
//  KUser+Serialize.m
//  Key
//
//  Created by Brendan Farmer on 3/14/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KUser+Serialize.h"
#import "IdentityKey.h"
#import "PreKey.h"

#define kCoderUniqueId @"uniqueId"
#define kCoderUsername @"username"
#define kCoderPasswordCrypt @"passwordCrypt"
#define kCoderIdentityKey @"identityKey"
#define kCoderPreKey @"preKey"

@implementation KUser(Serialize)

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    return [self initWithUniqueId:[aDecoder decodeObjectOfClass:[NSString class] forKey:kCoderUniqueId]
                         username:[aDecoder decodeObjectOfClass:[NSString class] forKey:kCoderUsername]
                    passwordCrypt:[aDecoder decodeObjectOfClass:[NSData class] forKey:kCoderPasswordCrypt]
                      identityKey:[aDecoder decodeObjectOfClass:[IdentityKey class] forKey:kCoderIdentityKey]
                           preKey:[aDecoder decodeObjectOfClass:[PreKey class] forKey:kCoderPreKey]];
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.uniqueId forKey:kCoderUniqueId];
    [aCoder encodeObject:self.username forKey:kCoderUsername];
    [aCoder encodeObject:self.passwordCrypt forKey:kCoderPasswordCrypt];
    [aCoder encodeObject:self.identityKey forKey:kCoderIdentityKey];
    [aCoder encodeObject:self.preKey forKey:kCoderPreKey];
}

@end