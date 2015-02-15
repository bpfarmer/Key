//
//  KOutgoingMessage.m
//  Key
//
//  Created by Brendan Farmer on 2/5/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KOutgoingMessage.h"
#import "KMessage.h"
#import "KUser.h"
#import "KKeyPair.h"

@implementation KOutgoingMessage

- (instancetype)initWithMessage:(KMessage *)message user:(KUser *)user {
    self = [super initWithUniqueId:nil];
    
    if (self) {
        _recipientId = user.uniqueId;
        _authorId    = message.authorId;
        _keyPairId   = [user.activeKeyPair uniqueId];
        _bodyCrypt   = [user.activeKeyPair encryptText:[message body]];
        _threadId    = message.threadId;
    }
    return self;
}

- (NSDictionary *)toDictionary {
    return @{@"authorId" : self.authorId,
             @"recipientId" : self.recipientId,
             @"keyPairId" : self.keyPairId,
             @"bodyCrypt" : self.bodyCrypt,
             @"threadId"  : self.threadId};
}

@end
