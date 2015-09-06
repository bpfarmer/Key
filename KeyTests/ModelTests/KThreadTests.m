//
//  KThreadTests.m
//  Key
//
//  Created by Brendan Farmer on 9/4/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "KThread.h"
#import "KStorageManager.h"
#import "KAccountManager.h"
#import "CollapsingFutures.h"
#import "KTestHelper.h"
#import "KUser.h"
#import "KPost.h"
#import "KMessage.h"

@interface KThreadTests : XCTestCase

@end

@implementation KThreadTests

- (void)setUp {
    [super setUp];
    [KTestHelper setup];
}

- (void)tearDown {
    [super tearDown];
    [KTestHelper tearDown];
}

- (void)testInit {
    KThread *thread = [[KThread alloc] initWithUsers:@[[KUser findById:@"1"], [KUser findById:@"2"], [KUser findById:@"3"], [KUser findById:@"4"], [KUser findById:@"1"]]];
    XCTAssert([thread.uniqueId isEqualToString:@"KThread_1_2_3_4"]);
    thread = [[KThread alloc] initWithUserIds:@[@"1", @"2", @"3", @"4", @"99"]];
    XCTAssert([thread.uniqueId isEqualToString:@"KThread_1_2_3_4_99"]);
    thread = [[KThread alloc] initWithUniqueId:@"KThread_1_2" name:@"Thread" latestMessageId:nil read:NO];
    XCTAssert([thread.uniqueId isEqualToString:@"KThread_1_2"]);
    XCTAssert([thread.name isEqualToString:@"Thread"]);
}

- (void)testAddRecipientIds {
    KThread *thread = [[KThread alloc] initWithUsers:@[[KUser findById:@"1"], [KUser findById:@"2"], [KUser findById:@"3"], [KUser findById:@"4"], [KUser findById:@"1"]]];
    [thread addRecipientIds:@[@"1", @"99"]];
    XCTAssert([thread.uniqueId isEqualToString:@"KThread_1_2_3_4_99"]);
}

- (void)testProcessLatestMessage {
    KThread *thread = [[KThread alloc] initWithUsers:@[[KUser findById:@"1"], [KUser findById:@"2"]]];
    [thread save];
    KPost *post = [[KPost alloc] initWithUniqueId:@"KPost_1" authorId:@"1" threadId:@"KThread_1" text:@"Test Text" createdAt:[NSDate date] ephemeral:NO attachmentIds:nil attachmentCount:1];
    [thread processLatestMessage:post];
    XCTAssert([thread.latestMessageId isEqualToString:post.uniqueId]);
    post = [[KPost alloc] initWithUniqueId:@"KPost_2" authorId:@"1" threadId:@"KThread_1" text:@"Test Text 2" createdAt:[NSDate date] ephemeral:NO attachmentIds:nil attachmentCount:1];
    [thread processLatestMessage:post];
    XCTAssert([thread.latestMessageId isEqualToString:post.uniqueId]);
    [post save];
    XCTAssert([thread.latestMessage.uniqueId isEqualToString:post.uniqueId]);
    post = [[KPost alloc] initWithUniqueId:@"KPost_3" authorId:@"1" threadId:@"KThread_1" text:@"Test Text 3" createdAt:[NSDate dateWithTimeIntervalSinceNow:0] ephemeral:NO attachmentIds:nil attachmentCount:1];
    XCTAssert(![thread.latestMessageId isEqualToString:post.uniqueId]);
}

- (void)testMessages {
    KThread *thread = [[KThread alloc] initWithUsers:@[[KUser findById:@"1"], [KUser findById:@"2"]]];
    XCTAssert(thread.messages.count == 0);
    KMessage *message = [[KMessage alloc] initWithAuthorId:@"1" threadId:thread.uniqueId body:@"Test"];
    [message save];
    XCTAssert(thread.messages.count == 1);
    message = [[KMessage alloc] initWithAuthorId:@"1" threadId:thread.uniqueId body:@"Test 2"];
    [message save];
    XCTAssert(thread.messages.count == 2);
    message = [[KMessage alloc] initWithAuthorId:@"1" threadId:thread.uniqueId body:@"Test 3"];
    [message save];
    XCTAssert(thread.messages.count == 3);
    XCTAssert([thread.messages isEqualToArray:[KMessage findAllByDictionary:@{@"threadId" : thread.uniqueId} orderBy:@"createdAt" descending:NO]]);
}

- (void)testPosts {
    KThread *thread = [[KThread alloc] initWithUsers:@[[KUser findById:@"1"], [KUser findById:@"2"]]];
    XCTAssert(thread.posts.count == 0);
    KPost *post = [[KPost alloc] initWithUniqueId:@"KPost_1" authorId:@"1" threadId:thread.uniqueId text:nil createdAt:[NSDate date] ephemeral:NO attachmentIds:nil attachmentCount:1];
    [post save];
    XCTAssert(thread.posts.count == 1);
    post = [[KPost alloc] initWithAuthorId:@"1"];
    [post addRecipientIds:@[@"2"]];
    [post save];
    XCTAssert(thread.posts.count == 2);
    post = [[KPost alloc] initWithAuthorId:@"2"];
    [post save];
    XCTAssert(thread.posts.count == 3);
}




@end
