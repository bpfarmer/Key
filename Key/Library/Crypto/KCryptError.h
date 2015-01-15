//
//  KKCryptError.h
//  Key
//
//  Created by Brendan Farmer on 1/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KError.h"

#define KCryptErrorEncrypt @"KCryptErrorEncrypt"
#define KCryptErrorDecrypt @"KCryptErrorDecrypt"
#define KCryptErrorAESCreation @"KCryptErrorAESCreation"
#define KCryptErrorAESUpdate @"KCryptErrorAESUpdate"
#define KCryptErrorAESFinal @"KCryptErrorAESFinal"
#define KCryptErrorAESPlainTextSize @"KCryptErrorAESPlainTextSize"
#define KCryptErrorRSACopyKey @"KCryptErrorRSACopyKey"
#define KCryptErrorRSATextLength @"KCryptErrorRSATextLength"
#define KCryptErrorRSAKeyFormat @"KCryptErrorRSAKeyFormat"
#define KCryptErrorRSAAddKey @"KCryptErrorRSAAddKey"
#define KCryptErrorRSARemoveKey @"KCryptErrorRSARemoveKey"
#define KCryptErrorRSAGenerateKey @"KCryptErrorRSAGenerateKey"
#define KCryptErrorSHAHash @"KCryptErrorSHAHash"


@interface KCryptError : KError

@end