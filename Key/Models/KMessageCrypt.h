//
//  KMessageCrypt.h
//  Key
//
//  Created by Brendan Farmer on 1/17/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Realm/Realm.h>

@class KMessage;
@class KKeyPair;
@class KUser;

@interface KMessageCrypt : RLMObject

@property KMessage *message;
@property NSString *recipientId;
@property NSString *keyPairId;
@property NSString *bodyCrypt;
@property NSData *attachmentsCrypt;
@property NSString *status;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<KMessageCrypt>
RLM_ARRAY_TYPE(KMessageCrypt)
