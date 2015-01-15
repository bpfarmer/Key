//
//  KError.m
//  key
//
//  Created by Brendan Farmer on 1/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KError.h"

#define KErrorClassKey @"class"
#define KErrorTypeKey @"errorType"

@implementation KError

- (id)init
{
    self = [super init];
    
    if (self)
    {
        self.errors = [[NSMutableArray alloc] init];
    }
    
    return self;
}

+ (BOOL)errorContainsErrors:(KError *)error;
{
    if (!error)
    {
        return NO;
    }
    
    return [error.errors count];
}

+ (BOOL)    error:(KError *)error
containsErrorType:(NSString *)errorType
       errorClass:(Class)errorClass
{
    if (!error)
    {
        return NO;
    }
    
    for (NSError *specificError in error.errors)
    {
        if (specificError.code == [errorType hash] && [[specificError.userInfo valueForKey:KErrorClassKey] isEqualToString:[errorClass description]])
        {
            return YES;
        }
    }
    
    return NO;
}

- (void)addErrorWithType:(NSString *)errorType
              errorClass:(Class)errorClass
{
    NSError *error = [[NSError alloc] initWithDomain:[[NSBundle mainBundle] bundleIdentifier] ? [[NSBundle mainBundle] bundleIdentifier] : @""
                                                code:[errorType hash]
                                            userInfo:@{
                                                       KErrorClassKey : [errorClass description],
                                                       KErrorTypeKey : errorType
                                                       }];
    
    [self.errors addObject:error];
}

- (void)appendErrorsFromError:(KError *)error
{
    [self.errors addObjectsFromArray:error.errors];
}

- (NSString *)description
{
    NSString *errorString = @"Errors:";
    
    for (NSError *error in self.errors)
    {
        errorString = [NSString stringWithFormat:
                       @"%@\n[%@:%@]",
                       errorString,
                       [error.userInfo valueForKey:KErrorClassKey],
                       [error.userInfo valueForKey:KErrorTypeKey]];
    }
    
    if ([self.errors count] == 0)
    {
        errorString = [NSString stringWithFormat:
                       @"%@ 0 Errors",
                       errorString];
    }
    
    return errorString;
}


@end
