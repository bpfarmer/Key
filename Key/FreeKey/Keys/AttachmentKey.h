//
//  AttachmentKey.h
//  Key
//
//  Created by Brendan Farmer on 7/17/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KDatabaseObject.h"

@interface AttachmentKey : KDatabaseObject

@property (nonatomic) NSData   *cipherKey;
@property (nonatomic) NSData   *iv;
@property (nonatomic) NSData   *macKey;

- (instancetype)init;

- (NSData *)encryptObject:(KDatabaseObject *)object;
- (KDatabaseObject *)decryptCipherText:(NSData *)cipherText;

@end
