//
//  FreeKeyResponseHandler.h
//  Key
//
//  Created by Brendan Farmer on 3/28/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PreKey;
@class PreKeyExchange;
@class EncryptedMessage;
@class Attachment;

@interface FreeKeyResponseHandler : NSObject

+ (PreKey *)createPreKeyFromRemoteDictionary:(NSDictionary *)dictionary;
+ (PreKeyExchange *)createPreKeyExchangeFromRemoteDictionary:(NSDictionary *)dictionary;
+ (EncryptedMessage *)createEncryptedMessageFromRemoteDictionary:(NSDictionary *)dictionary;
+ (Attachment *)createAttachmentFromRemoteDictionary:(NSDictionary *)dictionary;

@end
