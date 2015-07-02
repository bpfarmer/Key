//
//  KAttachment.m
//  Key
//
//  Created by Brendan Farmer on 4/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KAttachment.h"
#import "FreeKey.h"

@implementation KAttachment

- (instancetype)initWithCipherText:(NSData *)cipherText hmac:(NSData *)hmac messageUniqueId:(NSString *)messageUniqueId {
    self = [super init];
    
    if(self) {
        _cipherText = cipherText;
        _hmac       = hmac;
        _messageUniqueId = messageUniqueId;
    }
    
    return self;
}

+ (NSArray *)remoteKeys {
    return @[@"cipherText", @"hmac", @"messageUniqueId"];
}

+ (NSString *)remoteAlias {
    return kAttachmentRemoteAlias;
}

@end
