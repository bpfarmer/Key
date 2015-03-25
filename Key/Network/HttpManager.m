//
//  HttpManager.m
//  Key
//
//  Created by Brendan Farmer on 3/11/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "HttpManager.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "FreeKeyNetworkManager.h"
#import "NSData+Base64.h"
#import "NSString+Base64.h"
#import "EncryptedMessage.h"
#import "KAccountManager.h"
#import "HttpRequest.h"

#define kRemoteEndpoint @"https://polar-beyond-3981.herokuapp.com"

@implementation HttpManager

- (instancetype)init {
    self = [super init];
    if(self) {
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        _httpOperationManager = manager;
    }
    return self;
}

+ (instancetype)sharedManager {
    static HttpManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (void)put:(HttpRequest *)request
    success:(void (^)(AFHTTPRequestOperation *, id))success
    failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure {
    
    [self.httpOperationManager PUT:request.endpoint parameters:request.parameters success:success failure:failure];
}

- (void)post:(HttpRequest *)request
    success:(void (^)(AFHTTPRequestOperation *, id))success
    failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure {
    
    [self.httpOperationManager POST:request.endpoint parameters:request.parameters success:success failure:failure];
}

- (void)get:(HttpRequest *)request
     success:(void (^)(AFHTTPRequestOperation *, id))success
     failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure {
    
    [self.httpOperationManager GET:request.endpoint parameters:request.parameters success:success failure:failure];
}

- (void)post:(id <KSendable>)object {
    [self.httpOperationManager POST:[self endpointForObject:[self remoteAlias:object]]
       parameters:@{[self remoteAlias:object] : [self toDictionary:object]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if([responseObject[@"status"] isEqual:@"SUCCESS"]) {
            [object setRemoteStatus:kRemotePostSuccessStatus];
        } else {
            [object setRemoteStatus:kRemotePostFailureStatus];
        }
        [self fireNotification:kRemotePostNotification object:object];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [object setRemoteStatus:kRemotePostNetworkFailureStatus];
        [self fireNotification:kRemotePostNotification object:object];
    }];
}

- (void)getObjectsWithRemoteAlias:(NSString *)remoteAlias parameters:(NSDictionary *)parameters {
    [self.httpOperationManager GET:[self endpointForObject:remoteAlias] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
         if([responseObject[@"status"] isEqual:@"SUCCESS"]) {
             if([remoteAlias isEqualToString:kFeedRemoteAlias]) {
                 NSLog(@"RESPONSE OBJECT: %@", responseObject);
                 NSLog(@"BASE 64 DECODED RESPONSE OBJECT: %@", [self base64DecodedDictionary:responseObject]);
                 [[FreeKeyNetworkManager sharedManager] receiveRemoteFeed:[self base64DecodedDictionary:responseObject] withLocalUser:[KAccountManager sharedManager].user];
             }else {
                 [[FreeKeyNetworkManager sharedManager] receiveRemoteObject:[self base64DecodedDictionary:responseObject] ofType:remoteAlias];
             }
         }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // TODO: try again
    }];
}

- (void)batchPut:(NSString *)remoteAlias objects:(NSArray *)objects {
    [self.httpOperationManager PUT:[self endpointForObject:remoteAlias]
                        parameters:@{remoteAlias : objects}
                           success:^(AFHTTPRequestOperation *operation, id responseObject) {
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
}

- (void)fireNotification:(NSString *)notification object:(id <KSendable>)object {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:notification object:object];
    });
}

- (void)enqueueSendableObject:(id<KSendable>)object {
    dispatch_queue_t queue = dispatch_queue_create([kHTTPRequestQueue cStringUsingEncoding:NSASCIIStringEncoding], NULL);
    dispatch_async(queue, ^{
        [self put:object];
    });
}

- (void)enqueueGetWithRemoteAlias:(NSString *)remoteAlias parameters:(NSDictionary *)parameters {
    dispatch_queue_t queue = dispatch_queue_create([kHTTPRequestQueue cStringUsingEncoding:NSASCIIStringEncoding], NULL);
    dispatch_async(queue, ^{
        [self getObjectsWithRemoteAlias:remoteAlias parameters:parameters];
    });
}

- (NSDictionary *)toDictionary:(id <KSendable>)object {
    NSMutableDictionary *requestDictionary = [[NSMutableDictionary alloc] init];
    NSObject *objectForDictionary = (NSObject *)object;
    [[[object class] remoteKeys] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSObject *property = [objectForDictionary dictionaryWithValuesForKeys:@[obj]][obj];
        if([property isKindOfClass:[NSData class]]) {
            NSData *dataProperty = (NSData *)property;
            NSString *encodedString = [dataProperty base64EncodedString];
            [requestDictionary addEntriesFromDictionary:@{obj : encodedString}];
        }else {
            [requestDictionary addEntriesFromDictionary:@{obj : property}];
        }
    }];
    return requestDictionary;
}

/**
 * Method to convert Base64-encoded strings back to NSData. This might be the most
 * inefficient method in the world.
 * 
 * @param dictionary - Dictionary possibly containing Base64-encoded strings
 */
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

/*
 * This might be a bad idea, but to simplify the decoding step, we're collecting a list of
 * properties that are always NSData and always Base64 encoded, so we can decode before
 * handing off to the FreeKeyNetworkManager
 *
 * @return NSArray of all properties for KSendable objects that are of type NSData
 */
- (NSArray *)base64EncodedKeys {
    return @[@"senderRatchetKey", @"serializedData", @"sentSignedBaseKey", @"senderIdentityPublicKey", @"receiverIdentityPublicKey", @"baseKeySignature", @"signedPreKeyPublic", @"signedPreKeySignature", @"identityKey", @"publicKey"];
}

@end
