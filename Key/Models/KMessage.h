//
//  KMessage.h
//  Key
//
//  Created by Brendan Farmer on 1/17/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Realm/Realm.h>

@class KUser;
@class KGroup;
@class KMessageCrypt;

@interface KMessage : RLMObject

@property NSString *publicId;
@property KUser *author;
@property KGroup *group;
@property NSString *body;
@property NSData *attachments;
@property NSString *status;

- (BOOL)sendToServer;
- (KMessageCrypt *)encryptMessageToUser:(KUser *)user;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<KMessage>
RLM_ARRAY_TYPE(KMessage)
