//
//  KMessageCrypt.h
//  Key
//
//  Created by Brendan Farmer on 1/17/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "KYapDatabaseObject.h"

@class KKeyPair;
@class KUser;
@class KGroup;
@class KMessage;

@interface KMessageCrypt : KYapDatabaseObject

@property (nonatomic) NSString *recipientId;
@property (nonatomic) NSString *keyPairId;
@property (nonatomic) NSString *threadId;
@property (nonatomic) NSString *bodyCrypt;
@property (nonatomic) NSData *attachmentsCrypt;

- (instancetype)initWithMessage:(KMessage *)message keyPair:(KKeyPair *)keyPair;

@end
