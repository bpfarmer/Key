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
#define kCoderReceiverId @"receiverId"
#define kCoderSenderId @"senderId"

@implementation EncryptedMessage(Serialize)

+ (BOOL)supportsSecureCoding{
    return YES;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    return [self initWithSenderRatchetKey:[aDecoder decodeObjectOfClass:[NSData class] forKey:kCoderSenderRatchetKey]
                                 senderId:[aDecoder decodeObjectOfClass:[NSString class] forKey:kCoderSenderId]
                               receiverId:[aDecoder decodeObjectOfClass:[NSString class] forKey:kCoderReceiverId]
                           serializedData:[aDecoder decodeObjectOfClass:[NSData class] forKey:kCoderSerializedData]
                                    index:[aDecoder decodeObjectOfClass:[NSNumber class] forKey:kCoderPreviousIndex]
                            previousIndex:[aDecoder decodeObjectOfClass:[NSNumber class] forKey:kCoderIndex]];
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.senderRatchetKey forKey:kCoderSenderRatchetKey];
    [aCoder encodeObject:self.senderId forKey:kCoderSenderId];
    [aCoder encodeObject:self.receiverId forKey:kCoderReceiverId];
    [aCoder encodeObject:self.serializedData forKey:kCoderSerializedData];
    [aCoder encodeObject:self.index forKey:kCoderIndex];
    [aCoder encodeObject:self.previousIndex forKey:kCoderPreviousIndex];
}

+ (BOOL)hasUniqueId {
    return NO;
}

@end
