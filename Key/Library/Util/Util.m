//
//  Util.m
//  Key
//
//  Created by Brendan Farmer on 1/19/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "Util.h"

@implementation Util

+ (NSData *)generateRandomString:(NSInteger)length {
    uint8_t randomBytes[(size_t)length];
    SecRandomCopyBytes(kSecRandomDefault, (size_t)length, &randomBytes);
    return [[NSData alloc] initWithBytes:randomBytes length:length];
}

@end
