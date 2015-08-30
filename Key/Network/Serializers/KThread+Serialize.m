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
#define kCoderRead @"read"

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (id)initWithCoder:(NSCoder *)decoder {
    
    return [self initWithUniqueId:[decoder decodeObjectOfClass:[NSString class] forKey:kCoderUniqueId]
                             name:[decoder decodeObjectOfClass:[NSString class] forKey:kCoderName]
                  latestMessageId:[decoder decodeObjectOfClass:[KMessage class] forKey:kCoderLatestMessage]
                             read:[decoder decodeBoolForKey:kCoderRead]];
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.uniqueId forKey:kCoderUniqueId];
    [encoder encodeObject:self.name forKey:kCoderName];
    [encoder encodeObject:self.latestMessageId forKey:kCoderLatestMessage];
    [encoder encodeBool:self.read forKey:kCoderRead];
}


@end
