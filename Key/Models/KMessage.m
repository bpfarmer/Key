//
//  KMessage.m
//  Key
//
//  Created by Brendan Farmer on 1/17/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//
#import "KMessage.h"
#import "KGroup.h"
#import "KMessageCrypt.h"
#import "KUser.h"
#import "KKeyPair.h"

@implementation KMessage

- (BOOL)sendToServer {
    KGroup *group = [self group];
    NSMutableArray *messageCrypts = [NSMutableArray array];
    for(KUser *user in group.users) {
        [messageCrypts addObject:[self encryptMessageToUser:user]];
    }
    NSDictionary *messagesDictionary =
    @{
      @"Messages" : messageCrypts
    };
    
    return [self sendToServerMessageCrypts:messagesDictionary];
}

- (KMessageCrypt *)encryptMessageToUser:(KUser *)user {
    KMessageCrypt *messageCrypt = [[KMessageCrypt alloc] initWithMessage:self user:user];
    return messageCrypt;
}

+ (KMessage *)decryptMessageToUser:(KUser *)user {
    return [[KMessage alloc] init];
}

- (BOOL)sendToServerMessageCrypts:(NSDictionary *)messageCrypts {
    
    return YES;
}

- (NSArray *)yapDatabaseRelationshipEdges {
    NSArray *edges = nil;
    return edges;
}

@end
