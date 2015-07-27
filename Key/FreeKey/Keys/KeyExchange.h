//
//  KeyExchange.h
//  Key
//
//  Created by Brendan Farmer on 7/25/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KDatabaseObject.h"
#import "KSendable.h"

@interface KeyExchange : KDatabaseObject <KSendable>

- (NSString *)remoteUserId;
- (NSString *)remoteDeviceId;

- (void)saveAndAddDevice;

@end
