//
//  KPost+Serialize.m
//  Key
//
//  Created by Brendan Farmer on 4/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KPost+Serialize.h"
#import "KAttachment.h"

#define kCoderUniqueId @"uniqueId"
#define kCoderAuthorId @"authorId"
#define kCoderText     @"text"
#define kCoderCommentKey @"commentKey"
#define kCoderComments @"comments"
#define kCoderAttachmentKey @"attachmentKey"
#define kCoderAttachments @"attachments"
#define kCoderSeen @"seen"

@implementation KPost(Serialize)

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    return [self initWithUniqueId:[aDecoder decodeObjectOfClass:[NSString class] forKey:kCoderUniqueId]
                         authorId:[aDecoder decodeObjectOfClass:[NSString class] forKey:kCoderAuthorId]
                             text:[aDecoder decodeObjectOfClass:[NSString class] forKey:kCoderText]
                       commentKey:[aDecoder decodeObjectOfClass:[NSData class] forKey:kCoderCommentKey]
                         comments:[aDecoder decodeObjectOfClass:[NSArray class] forKey:kCoderComments]
                    attachmentKey:[aDecoder decodeObjectOfClass:[NSData class] forKey:kCoderAttachmentKey]
                      attachments:[aDecoder decodeObjectOfClass:[NSArray class] forKey:kCoderAttachments]
                             seen:[aDecoder decodeBoolForKey:kCoderSeen]];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.uniqueId forKey:kCoderUniqueId];
    [aCoder encodeObject:self.authorId forKey:kCoderAuthorId];
    [aCoder encodeObject:self.text forKey:kCoderText];
    [aCoder encodeObject:self.commentKey forKey:kCoderCommentKey];
    [aCoder encodeObject:self.comments forKey:kCoderComments];
    [aCoder encodeObject:self.attachmentKey forKey:kCoderAttachmentKey];
    [aCoder encodeObject:self.attachments forKey:kCoderAttachments];
    [aCoder encodeBool:self.seen forKey:kCoderSeen];
}

@end
