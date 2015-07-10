//
//  KOutgoingObject.m
//  Key
//
//  Created by Brendan Farmer on 6/14/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KOutgoingObject.h"
#import "KStorageManager.h"
#import "KDatabaseObject.h"

@implementation KOutgoingObject

- (instancetype)initWithObject:(KDatabaseObject *)object recipients:(NSArray *)recipients {
    self = [super initWithUniqueId:object.uniqueId];
    
    if(self) {
        _recipients = recipients;
    }
    
    return self;
}

+ (void)confirmDeliveryOfObject:(KDatabaseObject *)object toRecipient:(NSString *)recipientId {
    KOutgoingObject *outgoingObject = [KOutgoingObject findById:object.uniqueId];
    NSMutableArray *mutableRecipients = [NSMutableArray arrayWithArray:outgoingObject.recipients];
    [mutableRecipients removeObject:recipientId];
    outgoingObject.recipients = [NSArray arrayWithArray:mutableRecipients];
    if([outgoingObject.recipients count] > 0) [outgoingObject save];
    else [outgoingObject remove];
}

@end
