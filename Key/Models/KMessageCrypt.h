//
//  KMessageCrypt.h
//  Key
//
//  Created by Brendan Farmer on 1/17/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "KMessage.h"

@class KKeyPair;
@class KUser;
@class KGroup;

@interface KMessageCrypt : KMessage

@property (nonatomic) KUser *recipient;
@property (nonatomic) KKeyPair *keyPair;
@property (nonatomic) NSString *bodyCrypt;
@property (nonatomic) NSData *attachmentsCrypt;

- (instancetype)initWithMessage:(KMessage *)message user:(KUser *)user;

@end
