//
//  KMessageCrypt.m
//  Key
//
//  Created by Brendan Farmer on 1/17/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KMessageCrypt.h"
#import "KMessage.h"
#import "KUser.h"

@implementation KMessageCrypt

// Specify default values for properties

//+ (NSDictionary *)defaultPropertyValues
//{
//    return @{};
//}

// Specify properties to ignore (Realm won't persist these)

//+ (NSArray *)ignoredProperties
//{
//    return @[];
//}

- (NSDictionary *)toDictionary {
    return @{
      @"senderId" : self.message.author.publicId,
      @"recipientId" : self.recipient.publicId,
      @"groupId" : self.group.publicId,
      @"keyPairId" : self.keyPair.publicId,
      @"bodyCrypt" : self.bodyCrypt,
      @"attachmentsCrypt" : self.attachmentsCrypt
    };
    
}

@end
