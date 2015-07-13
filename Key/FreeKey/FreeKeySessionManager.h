//
//  FreeKeySessionManager.h
//  Key
//
//  Created by Brendan Farmer on 3/20/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Session;
@class KUser;
@class PreKey;
@class PreKeyExchange;
@class ECKeyPair;
@class TOCFuture;

@interface FreeKeySessionManager : NSObject

+ (instancetype)sharedManager;

/**
 * Returns a previously-created Session with provided localUser and remoteUser
 *
 * @param localUser The currently-logged-in user
 * @param remoteUser The remote user
 * 
 * @return TOCFuture futureSession
 */
- (TOCFuture *)sessionWithLocalUser:(KUser *)localUser remoteUser:(KUser *)remoteUser;

- (Session *)processNewKeyExchange:(NSObject *)keyExchange localUser:(KUser *)localUser remoteUser:(KUser *)remoteUser;

@end
