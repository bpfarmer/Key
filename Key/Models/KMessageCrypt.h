//
//  KMessageCrypt.h
//  Key
//
//  Created by Brendan Farmer on 1/17/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//
#import <Foundation/Foundation.h>

@class KMessage;
@class KKeyPair;
@class KUser;
@class KGroup;

@interface KMessageCrypt : NSObject <NSCoding>

@property (nonatomic) KMessage *message;
@property (nonatomic) KUser *recipient;
@property (nonatomic) KGroup *group;
@property (nonatomic) KKeyPair *keyPair;
@property (nonatomic) NSString *bodyCrypt;
@property (nonatomic) NSData *attachmentsCrypt;
@property (nonatomic) NSString *status;

- (NSDictionary *)toDictionary;

@end
