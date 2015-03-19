//
//  HttpManager.h
//  Key
//
//  Created by Brendan Farmer on 3/11/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KSendable.h"

#define kHTTPRequestQueue   @"httpRequestQueue"
#define kHTTPResponseQueue  @"httpResponseQueue"

@interface HttpManager : NSObject

+ (instancetype)sharedManager;

- (void)put:(id <KSendable>)object;
- (void)post:(id <KSendable>)object;
//- (void)get: (NSDictionary *)parameters;
- (void)batchPut:(NSString *)remoteAlias objects:(NSArray *)objects;
- (void)getObjectsWithRemoteAlias:(NSString *)remoteAlias parameters:(NSDictionary *)parameters;


@end
