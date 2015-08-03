//
//  HTTPRequest.m
//  Key
//
//  Created by Brendan Farmer on 3/25/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "HttpRequest.h"
#import "NSData+Base64.h"
#import "NSString+Base64.h"

@implementation HttpRequest

- (instancetype)initWithHttpMethod:(httpMethods)httpMethod endpoint:(NSString *)endpoint parameters:(NSDictionary *)parameters {
    self = [super init];
    if(self) {
        _httpMethod = httpMethod;
        _endpoint   = [self urlForEndpoint:endpoint];
        _parameters = parameters;
    }
    
    return self;
}

- (NSString *)urlForEndpoint:(NSString *)endpoint {
    return [NSString stringWithFormat:@"%@/%@", kRemoteEndpoint, endpoint];
}

- (void)makeRequestWithSuccess:(void (^)(AFHTTPRequestOperation *, id))success
                       failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure {
    
    switch(self.httpMethod) {
        case PUT:[[HttpManager sharedManager] put:self success:success failure:failure];
            break;
        case GET:[[HttpManager sharedManager] get:self success:success failure:failure];
            break;
        case POST:[[HttpManager sharedManager] post:self success:success failure:failure];
            break;
        case DELETE:
            break;
        default:
            break;
    }
}

- (NSDictionary *)toDictionary:(id <KSendable>)object {
    NSObject *objectForDictionary = (NSObject *)object;
    return [objectForDictionary dictionaryWithValuesForKeys:[[object class] remoteKeys]];
}

- (NSDictionary *)base64EncodedDictionary:(NSDictionary *)dictionary {
    NSMutableDictionary *requestDictionary = [[NSMutableDictionary alloc] init];
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if([obj isKindOfClass:[NSDictionary class]]) {
            [requestDictionary addEntriesFromDictionary:@{key : [self base64EncodedDictionary:obj]}];
        }else if([obj isKindOfClass:[NSData class]]) {
            NSData *dataProperty = (NSData *)obj;
            NSString *encodedString = [dataProperty base64EncodedString];
            [requestDictionary addEntriesFromDictionary:@{key : encodedString}];
        }else {
            [requestDictionary addEntriesFromDictionary:@{key : obj}];
        }
    }];
    return requestDictionary;
}

- (NSDictionary *)base64DecodedDictionary:(NSDictionary *)dictionary {
    NSMutableDictionary *decodedDictionary = [[NSMutableDictionary alloc] initWithDictionary:dictionary];
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if([obj isKindOfClass:[NSArray class]]) {
            NSArray *arrayObject = (NSArray *)obj;
            NSMutableArray *decodedArrayObject = [[NSMutableArray alloc] init];
            [arrayObject enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                if([obj isKindOfClass:[NSDictionary class]]) {
                    [decodedArrayObject addObject:[self base64DecodedDictionary:obj]];
                }else if([[self base64EncodedKeys] containsObject:key]) {
                    NSString *stringObject = (NSString *)obj;
                    [decodedArrayObject addObject:[stringObject base64DecodedData]];
                }
            }];
            [decodedDictionary setObject:decodedArrayObject forKey:key];
        }else if([obj isKindOfClass:[NSDictionary class]]) {
            [decodedDictionary setObject:[self base64DecodedDictionary:obj] forKey:key];
        }
        if([[self base64EncodedKeys] containsObject:key]) {
            NSString *stringObject = (NSString *)obj;
            [decodedDictionary setObject:[stringObject base64DecodedData] forKey:key];
        }
    }];
    return decodedDictionary;
}

- (NSArray *)base64EncodedKeys {
    return @[@"senderRatchetKey", @"serializedData", @"basePublicKey", @"senderPublicKey",  @"baseKeySignature", @"basePublicKey", @"signature", @"identityKey", @"publicKey"];
}

@end
