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
#define kCoderText     @"text"
#define kCoderCommentKey @"commentKey"
#define kCoderComments @"comments"
#define kCoderAttachmentKey @"attachmentKey"
#define kCoderAttachments @"attachments"
#define kCoderSeen @"seen"
#define kCoderCreatedAt @"createdAt"

@implementation KPost(Serialize)

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    return [self initWithUniqueId:[aDecoder decodeObjectOfClass:[NSString class] forKey:kCoderUniqueId]
                         authorId:[aDecoder decodeObjectOfClass:[NSString class] forKey:kCoderAuthorId]
                             text:[aDecoder decodeObjectOfClass:[NSString class] forKey:kCoderText]
                      attachments:[aDecoder decodeObjectOfClass:[NSArray class] forKey:kCoderAttachments]
                        createdAt:[aDecoder decodeObjectOfClass:[NSDate class] forKey:kCoderCreatedAt]];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.uniqueId forKey:kCoderUniqueId];
    [aCoder encodeObject:self.authorId forKey:kCoderAuthorId];
    [aCoder encodeObject:self.text forKey:kCoderText];
    [aCoder encodeObject:self.createdAt forKey:kCoderCreatedAt];
}

@end
