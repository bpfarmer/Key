//
//  KPost+Serialize.m
//  Key
//
//  Created by Brendan Farmer on 4/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KPost+Serialize.h"

#define kCoderUniqueId @"uniqueId"
#define kCoderAuthorId @"authorId"
#define kCoderThreadId @"threadId"
#define kCoderText     @"text"
#define kCoderCommentKey @"commentKey"
#define kCoderComments @"comments"
#define kCoderAttachmentKey @"attachmentKey"
#define kCoderAttachments @"attachments"
#define kCoderSeen @"seen"
#define kCoderCreatedAt @"createdAt"
#define kCoderEphemeral @"ephemeral"
#define kCoderAttachmentIds @"attachmentIds"
#define kCoderAttachmentCount @"attachmentCount"

@implementation KPost(Serialize)

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    return [self initWithUniqueId:[aDecoder decodeObjectOfClass:[NSString class] forKey:kCoderUniqueId]
                         authorId:[aDecoder decodeObjectOfClass:[NSString class] forKey:kCoderAuthorId]
                         threadId:[aDecoder decodeObjectOfClass:[NSString class] forKey:kCoderThreadId]
                             text:[aDecoder decodeObjectOfClass:[NSString class] forKey:kCoderText]
                        createdAt:[aDecoder decodeObjectOfClass:[NSDate class] forKey:kCoderCreatedAt]
                        ephemeral:[aDecoder decodeBoolForKey:kCoderEphemeral]
                    attachmentIds:[aDecoder decodeObjectOfClass:[NSString class] forKey:kCoderAttachmentIds]
                  attachmentCount:[aDecoder decodeIntegerForKey:kCoderAttachmentCount]];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.uniqueId forKey:kCoderUniqueId];
    [aCoder encodeObject:self.authorId forKey:kCoderAuthorId];
    [aCoder encodeObject:self.threadId forKey:kCoderThreadId];
    [aCoder encodeObject:self.text forKey:kCoderText];
    [aCoder encodeObject:self.createdAt forKey:kCoderCreatedAt];
    [aCoder encodeBool:self.ephemeral forKey:kCoderEphemeral];
    [aCoder encodeObject:self.attachmentIds forKey:kCoderAttachmentIds];
    [aCoder encodeInteger:self.attachments.count forKey:kCoderAttachmentCount];
}

@end
