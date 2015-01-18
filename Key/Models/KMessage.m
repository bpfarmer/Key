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
        [messageCrypts addObject:[self encryptMessageToUser:user]];
    }
    
    return YES;
}

- (KMessageCrypt *)encryptMessageToUser:(KUser *)user {
    KKeyPair *keyPair = [user activeKeyPair];
    KMessageCrypt *messageCrypt = [[KMessageCrypt alloc] init];
    messageCrypt.message = self;
    messageCrypt.recipientId = user.publicId;
    messageCrypt.keyPairId = keyPair.publicId;
    messageCrypt.bodyCrypt = [keyPair encryptText:self.body];
    messageCrypt.attachmentsCrypt = [keyPair encryptData:self.attachments];
    return messageCrypt;
}

- (BOOL)sendToServerMessageCrypts:(NSArray *)messageCrypts {
    return YES;
}

@end
