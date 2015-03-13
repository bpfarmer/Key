//
//  Util.m
//  Key
//
//  Created by Brendan Farmer on 1/19/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "Util.h"

@implementation Util

+ (NSData *)generateRandomData:(NSInteger)length {
    uint8_t randomBytes[(size_t)length];
    SecRandomCopyBytes(kSecRandomDefault, (size_t)length, &randomBytes);
    return [[NSData alloc] initWithBytes:randomBytes length:length];
}

+ (NSString *)insecureRandomString:(NSInteger)length {
    NSString *alphabet  = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXZY0123456789";
    NSMutableString *s = [NSMutableString stringWithCapacity:20];
    for (NSUInteger i = 0U; i < length; i++) {
        u_int32_t r = arc4random() % [alphabet length];
        unichar c = [alphabet characterAtIndex:r];
        [s appendFormat:@"%C", c];
    }
    return s;
}

@end
