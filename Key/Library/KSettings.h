//
//  KSettings.h
//  Key
//
//  Created by Brendan Farmer on 1/20/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KSettings : NSObject

@end

#define kUserUsernameRegistrationEndpoint @"http://127.0.0.1:9393/user.json"
#define kUserFinishRegistrationEndpoint @"http://127.0.0.1:9393/user.json"
#define kUserGetUsersEndpoint @"http://127.0.0.1:9393/users.json"
#define kMessageSendMessagesEndpoint @"http://127.0.0.1:9393/messages.json"