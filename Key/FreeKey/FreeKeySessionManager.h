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
 * Returns a TOCFuture token when the only information given is a remote user id
 *
 * @param remoteUserId The remote user
 *
 * @return TOCFuture futureSession
 */
- (TOCFuture *)sessionForRemoteUserId:(NSString *)remoteUserId;

/**
 * Returns a previously-created Session with provided localUser and remoteUser
 *
 * @param localUser The currently-logged-in user
 * @param remoteUser The remote user
 * 
 * @return TOCFuture futureSession
 */
- (TOCFuture *)sessionWithLocalUser:(KUser *)localUser remoteUser:(KUser *)remoteUser;

/**
 * Creates a session spontaneously, without a specific PreKey or PreKeyExchange. Using
 * a PreKey or PreKeyExchange explicitly is preferred. This checks for a local PreKey, then
 * a local PreKeyExchange, if either exist, it uses the supplied data to create a new Session.
 *
 * @param localUser The currently-logged-in user
 * @param remoteUser The remote user
 *
 * @return session The created session.
 */
- (Session *)createSessionWithLocalUser:(KUser *)localUser remoteUser:(KUser *)remoteUser;

/**
 * Creates a session in the case that we have a remote user's PreKey
 *
 * @param localUser The currently logged-in user
 * @param remoteUser The remote user associated with the PreKey
 * @param ourBaseKey A Curve-25519 ephemeral KeyPair
 * @param theirPreKey The retrieved PreKey for the remote user
 *
 * @return session The newly-created Session object
 */
- (Session *)createSessionWithLocalUser:(KUser *)localUser
                             remoteUser:(KUser *)remoteUser
                             ourBaseKey:(ECKeyPair *)ourBaseKey
                            theirPreKey:(PreKey *)theirPreKey;

/**
 * Creates a session in the case that we have a PreKeyExchange from a remote user
 *
 * @param localUser The currently logged-in user
 * @param remoteUser The remote user associated with the PreKey
 * @param ourPreKey A previously-generated PreKey
 * @param theirPreKeyExchange The received PreKeyExchange from the remote user
 *
 * @return session The newly-created Session object
 */
- (Session *)createSessionWithLocalUser:(KUser *)localUser
                             remoteUser:(KUser *)remoteUser
                              ourPreKey:(PreKey *)ourPreKey
                    theirPreKeyExchange:(PreKeyExchange *)theirPreKeyExchange;

- (PreKey *)getPreKeyForUserId:(NSString *)userId;
- (PreKeyExchange *)getPreKeyExchangeForUserId:(NSString *)userId;

- (Session *)processNewKeyExchange:(id)keyExchange localUser:(KUser *)localUser remoteUser:(KUser *)remoteUser;

/**
 * Processes a newly received PreKey from a remote user retrieved by a local user. If a session already exists
 * the new PreKey is ignored, and if the local user has already received a PreKeyExchange from the remote user
 * the PreKey is ignored and the session is generated.
 *
 * @param preKey PreKey for the remote user
 * @param localUser The currently logged-in local user
 * @param remoteUser The remote user associated with the PreKey
 *
 * @return session The created or retrieved session object
 */
- (Session *)processNewPreKey:(PreKey *)preKey localUser:(KUser *)localUser remoteUser:(KUser *)remoteUser;

/**
 * Processes a newly-received PreKeyExchange from a remote user to the local user. If a session already
 * exists between the local and remote users, we ignore this PreKeyExchange, otherwise, we create the session
 *
 * @param preKeyExchange The received PreKeyExchange
 * @param localUser The currently-logged-in user
 * @param remoteUser The remote user
 *
 * @return session The created or retrieved session
 */
- (Session *)processNewPreKeyExchange:(PreKeyExchange *)preKeyExchange
                            localUser:(KUser *)localUser
                           remoteUser:(KUser *)remoteUser;

@end
