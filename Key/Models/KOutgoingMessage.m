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
    }
    return self;
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *outgoingMessageDictionary = [[NSMutableDictionary alloc] init];
    if(self.authorId) [outgoingMessageDictionary addEntriesFromDictionary:@{@"authorId" : self.authorId}];
    if(self.recipientId) [outgoingMessageDictionary addEntriesFromDictionary:@{@"recipientId" : self.recipientId}];
    if(self.keyPairId) [outgoingMessageDictionary addEntriesFromDictionary:@{@"keyPairId" : self.keyPairId}];
    if(self.bodyCrypt) [outgoingMessageDictionary addEntriesFromDictionary:@{@"bodyCrypt" : self.bodyCrypt}];
    return outgoingMessageDictionary;
}

@end
