//
//  KOutgoingObject.m
//  Key
//
//  Created by Brendan Farmer on 6/14/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KOutgoingObject.h"
#import "KStorageManager.h"

@implementation KOutgoingObject

- (instancetype)initWithObject:(id<KEncryptable>)object recipients:(NSArray *)recipients {
    self = [super initWithUniqueId:object.uniqueId];
    
    if(self) {
        _recipients = recipients;
    }
    
    return self;
}

+ (void)confirmDeliveryOfObject:(id<KEncryptable>)object toRecipient:(NSString *)recipientId {
    KOutgoingObject *outgoingObject = [[KStorageManager sharedManager] objectForKey:object.uniqueId inCollection:[KOutgoingObject collection]];
    NSMutableArray *mutableRecipients = [NSMutableArray arrayWithArray:outgoingObject.recipients];
    [mutableRecipients removeObject:recipientId];
    outgoingObject.recipients = [NSArray arrayWithArray:mutableRecipients];
    if([outgoingObject.recipients count] > 0)
        [outgoingObject save];
    else
        [[KStorageManager sharedManager]removeObjectForKey:outgoingObject.uniqueId inCollection:[self collection]];
}

@end
