//
//  KMessageTests.m
//  Key
//
//  Created by Brendan Farmer on 9/4/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "KMessage.h"
#import "KStorageManager.h"
#import "KAccountManager.h"
#import "CollapsingFutures.h"
#import "KUser.h"
#import "KTestHelper.h"
#import "KThread.h"

@interface KMessageTests : XCTestCase

@end

@implementation KMessageTests

- (void)setUp {
    [super setUp];
    [KTestHelper setup];
}

- (void)tearDown {
    [super tearDown];
    [KTestHelper tearDown];
}

- (void)testInit {
    KMessage *message = [[KMessage alloc] initWithAuthorId:@"1" threadId:@"KThread_1_2" body:@"test"];
    XCTAssert([message.authorId isEqualToString:@"1"]);
    XCTAssert([message.threadId isEqualToString:@"KThread_1_2"]);
    XCTAssert([message.body isEqualToString:@"test"]);
    NSDate *date = [NSDate date];
    message = [[KMessage alloc] initWithUniqueId:@"KMessage_1" authorId:@"1" threadId:@"KThread_1_2" body:@"test" status:@"Created" createdAt:date];
    XCTAssert([message.uniqueId isEqualToString:@"KMessage_1"]);
    XCTAssert([message.authorId isEqualToString:@"1"]);
    XCTAssert([message.threadId isEqualToString:@"KThread_1_2"]);
    XCTAssert([message.body isEqualToString:@"test"]);
    XCTAssert([message.status isEqualToString:@"Created"]);
    XCTAssert([message.createdAt isEqualToDate:date]);
}

- (void)testAuthor {
    KMessage *message = [[KMessage alloc] initWithAuthorId:@"1" threadId:@"KThread_1_2" body:@"test"];
    NSLog(@"MESSAGE AUTHOR: %@", message.author);
    XCTAssert([message.author.uniqueId isEqualToString:@"1"]);
}

- (void)testUniqueId {
    XCTAssert([[KMessage generateUniqueId] containsString:@"KMessage"]);
}

- (void)testThreadProcessing {
    KMessage *message = [[KMessage alloc] initWithUniqueId:@"KMessage_1" authorId:@"1" threadId:@"KThread_1_2" body:@"test" status:@"Created" createdAt:[NSDate date]];
    XCTAssert([KThread findById:message.threadId]);
    [message save];
    NSLog(@"THREAD: %@", [KThread findById:message.threadId]);
    XCTAssert([[KThread findById:message.threadId].latestMessageId isEqualToString:message.uniqueId]);
    message = [[KMessage alloc] initWithUniqueId:@"KMessage_2" authorId:@"1" threadId:@"KThread_1_2" body:@"test" status:@"Created" createdAt:[NSDate dateWithTimeIntervalSince1970:0]];
    [message save];
    XCTAssert(![[KThread findById:message.threadId].latestMessageId isEqualToString:message.uniqueId]);
}


@end
