//
//  Util.h
//  Key
//
//  Created by Brendan Farmer on 1/19/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Util : NSObject

+ (NSData *)generateRandomString:(NSInteger)length;
+ (NSString *)insecureRandomString:(NSInteger)length;

@end
