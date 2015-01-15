//
//  KError.h
//  Key
//
//  Created by Brendan Farmer on 1/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KError;

@interface KError : NSObject

@property (nonatomic, retain) NSMutableArray *errors;

- (void)addErrorWithType:(NSString *)errorType
              errorClass:(Class)errorClass;

- (void)appendErrorsFromError:(KError *)error;

+ (BOOL)errorContainsErrors:(KError *)error;

+ (BOOL)    error:(KError *)error
containsErrorType:(NSString *)errorType
       errorClass:(Class)errorClass;

@end