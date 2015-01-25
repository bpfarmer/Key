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

// Specify default values for properties

//+ (NSDictionary *)defaultPropertyValues
//{
//    return @{};
//}

// Specify properties to ignore (Realm won't persist these)

//+ (NSArray *)ignoredProperties
//{
//    return @[];
//}

- (BOOL)sendToServer {
    KGroup *group = [self group];
    NSMutableArray *messageCrypts = [NSMutableArray array];
    for(KUser *user in group.users) {
        [messageCrypts addObject:[[self encryptMessageToUser:user] toDictionary]];
    }
    NSDictionary *messagesDictionary =
    @{
      @"Messages" : messageCrypts
    };
    
    return [self sendToServerMessageCrypts:messagesDictionary];
}

- (KMessageCrypt *)encryptMessageToUser:(KUser *)user {
    KKeyPair *keyPair = [user activeKeyPair];
    KMessageCrypt *messageCrypt = [[KMessageCrypt alloc] init];
    messageCrypt.message = self;
    messageCrypt.recipient = user;
    messageCrypt.keyPair = keyPair;
    messageCrypt.bodyCrypt = [keyPair encryptText:self.body];
    messageCrypt.attachmentsCrypt = [keyPair encryptData:self.attachments];
    return messageCrypt;
}

+ (KMessage *)decryptMessageToUser:(KUser *)user {
    return [[KMessage alloc] init];
}

- (BOOL)sendToServerMessageCrypts:(NSDictionary *)messageCrypts {
    
    return YES;
}

@end
