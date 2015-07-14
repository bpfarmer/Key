//
//  KMessage.h
//  Key
//
//  Created by Brendan Farmer on 1/17/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "KDatabaseObject.h"
#import "KEncryptable.h"
#import "JSQMessageData.h"

@class KUser;
@class KGroup;
@class KMessageCrypt;
@class KThread;
@class KAttachment;

@interface KMessage : KDatabaseObject <JSQMessageData>

@property (nonatomic) NSString *authorId;
@property (nonatomic) NSString *threadId;
@property (nonatomic) NSString *body;
@property (nonatomic) NSString *status;
@property (nonatomic) BOOL read;
@property (nonatomic) NSDate *createdAt;
@property (nonatomic) NSData *attachmentKey;

- (instancetype)initWithAuthorId:(NSString *)authorId threadId:(NSString *)threadId body:(NSString *)body;
- (instancetype)initWithUniqueId:(NSString *)uniqueId
                        authorId:(NSString *)authorId
                        threadId:(NSString *)threadId
                            body:(NSString *)body
                          status:(NSString *)status
                       createdAt:(NSDate *)createdAt;

@end
