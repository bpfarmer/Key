//
//  KThread+Serialize.m
//  Key
//
//  Created by Brendan Farmer on 3/19/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KThread+Serialize.h"
#import "KMessage.h"

@implementation KThread(Serialize)

#define kCoderUniqueId @"uniqueId"
#define kCoderUserIds @"userIds"
#define kCoderName @"name"
#define kCoderLatestMessage @"latestMessage"
#define kCoderLastMessageAt @"lastMessageAt"
#define kCoderArchivedAt @"archivedAt"

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (id)initWithCoder:(NSCoder *)decoder {
    
    return [self initWithUniqueId:[decoder decodeObjectOfClass:[NSString class] forKey:kCoderUniqueId]
                          userIds:[decoder decodeObjectOfClass:[NSArray class] forKey:kCoderUserIds]
                             name:[decoder decodeObjectOfClass:[NSString class] forKey:kCoderName]
                    latestMessage:[decoder decodeObjectOfClass:[KMessage class] forKey:kCoderLatestMessage]
                    lastMessageAt:[decoder decodeObjectOfClass:[NSDate class] forKey:kCoderLastMessageAt]
                       archivedAt:[decoder decodeObjectOfClass:[NSDate class] forKey:kCoderArchivedAt]];
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.uniqueId forKey:kCoderUniqueId];
    [encoder encodeObject:self.userIds forKey:kCoderUserIds];
    [encoder encodeObject:self.name forKey:kCoderName];
    [encoder encodeObject:self.latestMessage forKey:kCoderLatestMessage];
    [encoder encodeObject:self.lastMessageAt forKey:kCoderLastMessageAt];
    [encoder encodeObject:self.archivedAt forKey:kCoderArchivedAt];
}


@end
