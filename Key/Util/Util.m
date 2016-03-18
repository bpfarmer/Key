//
//  Util.m
//  Key
//
//  Created by Brendan Farmer on 1/19/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "Util.h"

@implementation Util


+ (NSData *)generateRandomData:(int)numberBytes {
    NSMutableData* randomBytes = [NSMutableData dataWithLength:numberBytes];
    int err = 0;
    err = SecRandomCopyBytes(kSecRandomDefault,numberBytes,[randomBytes mutableBytes]);
    if(err != noErr && [randomBytes length] != numberBytes) {
        //@throw [NSException exceptionWithName:@"random problem" reason:@"problem generating the random " userInfo:nil];
    }
    return [NSData dataWithData:randomBytes];
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
