//
//  EncryptedMessage+Serialize.m
//  Key
//
//  Created by Brendan Farmer on 3/16/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "EncryptedMessage+Serialize.h"

#define kCoderIndex @"index"
#define kCoderPreviousIndex @"previousIndex"
#define kCoderCipherText @"cipherText"
#define kCoderSenderRatchetKey @"senderRatchetKey"
#define kCoderSerializedData @"serializedData"

@implementation EncryptedMessage(Serialize)

+ (BOOL)supportsSecureCoding{
    return YES;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    NSNumber *index = (NSNumber *)[aDecoder decodeObjectOfClass:[NSNumber class] forKey:kCoderIndex];
    NSNumber *previousIndex = (NSNumber *)[aDecoder decodeObjectOfClass:[NSNumber class] forKey:kCoderPreviousIndex];
    return [self initWith];
    
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.keyData forKey:kCoderKeyData];
    NSNumber *index = [NSNumber numberWithInt:self.index];
    [aCoder encodeObject:index forKey:kCoderIndex];
}

@end
