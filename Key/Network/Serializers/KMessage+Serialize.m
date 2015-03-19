//
//  KMessage+Serialize.m
//  Key
//
//  Created by Brendan Farmer on 3/14/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KMessage+Serialize.h"
#import "KThread.h"
#import "KStorageManager.h"

#define kCoderUniqueId @"uniqueId"
#define kCoderAuthorId @"authorId"
#define kCoderThreadId @"threadId"
#define kCoderBody @"body"
#define kCoderCreatedAt @"createdAt"
#define kCoderStatus @"status"
#define kCoderCreatedAt @"createdAt"

@implementation KMessage(Serialize)

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (id)initWithCoder:(NSCoder *)decoder {    
    return [self initWithUniqueId:[decoder decodeObjectOfClass:[NSString class] forKey:kCoderUniqueId]
                         authorId:[decoder decodeObjectOfClass:[NSString class] forKey:kCoderAuthorId]
                         threadId:[decoder decodeObjectOfClass:[NSString class] forKey:kCoderThreadId]
                             body:[decoder decodeObjectOfClass:[NSString class] forKey:kCoderBody]
                           status:[decoder decodeObjectOfClass:[NSString class] forKey:kCoderStatus]
                        // TODO: convert provided timestamp to NSDate
                        createdAt:[decoder decodeObjectOfClass:[NSDate class] forKey:kCoderCreatedAt]];
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.uniqueId forKey:kCoderUniqueId];
    [encoder encodeObject:self.authorId forKey:kCoderAuthorId];
    [encoder encodeObject:self.threadId forKey:kCoderThreadId];
    [encoder encodeObject:self.body forKey:kCoderBody];
    [encoder encodeObject:self.status forKey:kCoderStatus];
    [encoder encodeObject:self.createdAt forKey:kCoderCreatedAt];
}


@end
