//
//  KYapDatabaseSecondaryIndex.h
//  Key
//
//  Created by Brendan Farmer on 2/12/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YapDatabase/YapDatabaseTransaction.h>
#import <YapDatabase/YapDatabaseSecondaryIndex.h>

@interface KYapDatabaseSecondaryIndex : NSObject

+ (BOOL)registerUsernameIndex;

@end

#define KUsernameSQLiteIndex @"KUsernameIndex"
