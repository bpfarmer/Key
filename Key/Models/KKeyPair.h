//
//  KKeyPair.h
//  Key
//
//  Created by Brendan Farmer on 1/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Realm/Realm.h>

@interface KKeyPair : RLMObject

@property NSString *privateKey;
@property NSString *publicKey;
@property NSString *encryptionAlgorithm;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<KKeyPair>
RLM_ARRAY_TYPE(KKeyPair)
