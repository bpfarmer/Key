//
//  KPostTests.m
//  Key
//
//  Created by Brendan Farmer on 9/4/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "KPost.h"
#import "KUser.h"
#import "KAccountManager.h"
#import "KThread.h"
#import "KTestHelper.h"
#import "CollapsingFutures.h"
#import "KObjectRecipient.h"
#import "KPhoto.h"
#import "KLocation.h"

@interface KPostTests : XCTestCase

@end

@implementation KPostTests

- (void)setUp {
    [super setUp];
    [KTestHelper setup];
}

- (void)tearDown {
    [super tearDown];
    [KTestHelper tearDown];
}

- (void)testCreationWithAuthor {
    KPost *post = [[KPost alloc] initWithAuthorId:@"1"];
    XCTAssert([post.authorId isEqualToString:@"1"]);
    XCTAssert(!post.read);
    XCTAssert([post.createdAt compare:[NSDate date]] == -1);
    XCTAssert([post.createdAt compare:[[NSDate date] dateByAddingTimeInterval:-60]] == 1);
}

- (void)testCreationWithProperties {
    NSDate *date = [NSDate date];
    KPost *post = [[KPost alloc] initWithUniqueId:@"KPost_1" authorId:@"1" threadId:@"KThread_1" text:nil createdAt:date ephemeral:NO attachmentIds:nil attachmentCount:1];
    XCTAssert(!post.read);
    XCTAssert(!post.ephemeral);
    XCTAssert([post.authorId isEqualToString:@"1"]);
    XCTAssert([post.uniqueId isEqualToString:@"KPost_1"]);
    XCTAssert([date isEqualToDate:post.createdAt]);
    XCTAssert([post.threadId isEqualToString:@"KThread_1"]);
}

- (void)testAuthor {
    KPost *post = [[KPost alloc] initWithAuthorId:@"1"];
    XCTAssert([post.author.uniqueId isEqualToString:[KAccountManager sharedManager].user.uniqueId]);
}

- (void)testThread {
    KPost *post = [[KPost alloc] initWithUniqueId:@"KPost_1" authorId:@"1" threadId:@"KThread_1" text:nil createdAt:nil ephemeral:NO attachmentIds:nil attachmentCount:0];
    [post save];
    XCTAssert(post.threads.count > 0);
    post.threadId = nil;
    XCTAssert(post.threads.count == 0);
}

- (void)testSetupThread {
    KPost *post = [[KPost alloc] initWithAuthorId:@"1"];
    [post addRecipientIds:@[@"1", @"2", @"3"]];
    [post save];
    KThread *thread1 = [KThread findById:@"KThread_1_2"];
    KThread *thread2 = [KThread findById:@"KThread_1_3"];
    XCTAssert(thread1);
    XCTAssert(thread2);
    XCTAssert([thread1.latestMessageId isEqualToString:post.uniqueId]);
    XCTAssert([thread2.latestMessageId isEqualToString:post.uniqueId]);
    post = [[KPost alloc] initWithUniqueId:@"KPost_3" authorId:@"2" threadId:nil text:nil createdAt:[NSDate date] ephemeral:NO attachmentIds:nil attachmentCount:0];
    [post save];
    KThread *thread = post.threads.firstObject;
    XCTAssert([thread.uniqueId isEqualToString:@"KThread_1_2"]);
    XCTAssert([thread.latestMessageId isEqualToString:post.uniqueId]);
    post = [[KPost alloc] initWithUniqueId:@"KPost_4" authorId:@"2" threadId:@"KThread_1_2_3" text:nil createdAt:[NSDate date] ephemeral:NO attachmentIds:nil attachmentCount:0];
    [post save];
    thread = post.threads.firstObject;
    XCTAssert([thread.uniqueId isEqualToString:post.threadId]);
    XCTAssert([thread.latestMessageId isEqualToString:post.uniqueId]);
}

- (void)testAddingRecipients {
    KPost *post = [[KPost alloc] initWithAuthorId:@"1"];
    NSLog(@"RECIPIENT IDS: %@", post.recipientIds);
    XCTAssert(post.recipientIds.count == 0);
    [post addRecipientIds:@[@"1", @"2", @"3"]];
    NSArray *recipients = @[@"2", @"3"];
    XCTAssert([post.recipientIds isEqualToArray:recipients]);
    KUser *user4 = [[KUser alloc] initWithUniqueId:@"4" username:@"4" publicKey:nil];
    [user4 save];
    KUser *user5 = [[KUser alloc] initWithUniqueId:@"5" username:@"5" publicKey:nil];
    [user5 save];
    [post addRecipientIds:@[@"4", @"5"]];
    recipients = @[@"2", @"3", @"4", @"5"];
    XCTAssert([post.recipientIds isEqualToArray:recipients]);
}

- (void)testUnread {
    KPost *post = [[KPost alloc] initWithAuthorId:@"1"];
    [post save];
    post = [[KPost alloc] initWithAuthorId:@"2"];
    post.read = YES;
    [post save];
    post = [[KPost alloc] initWithAuthorId:@"2"];
    [post save];
    post = [[KPost alloc] initWithAuthorId:@"2"];
    [post save];
    XCTAssert([KPost unread].count == 2);
}

- (void)testUnsavedPropertyList {
    NSArray *array = @[@"preview"];
    XCTAssert([[KPost unsavedPropertyList] isEqualToArray:array]);
}

- (void)testAttachments {
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"beach" ofType:@"jpg"];
    NSData *img = [NSData dataWithContentsOfFile:imagePath];
    KPhoto *photo = [[KPhoto alloc] initWithMedia:img];
    KPost *post = [[KPost alloc] initWithAuthorId:@"1"];
    [post addAttachment:photo];
    KLocation *location = [[KLocation alloc] initWithAuthorId:[KAccountManager sharedManager].uniqueId location:[KAccountManager sharedManager].currentCoordinate];
    [post addAttachment:location];
    [post save];
    XCTAssert([post attachmentsOfType:@"KPhoto"].count == 1);
    XCTAssert([post attachmentsOfType:@"KLocation"].count == 1);
    XCTAssert(post.attachments.count == 2);
    [post remove];
    XCTAssert([KPost all].count == 0);
    XCTAssert([KPhoto all].count == 0);
    XCTAssert([KLocation all].count == 0);
    
}

- (void)testPhotoAttachment {
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"beach" ofType:@"jpg"];
    NSData *img = [NSData dataWithContentsOfFile:imagePath];
    KPhoto *photo = [[KPhoto alloc] initWithMedia:img];
    KPost *post = [[KPost alloc] initWithAuthorId:@"1"];
    [post addAttachment:photo];
    XCTAssert([photo.parentId isEqualToString:post.uniqueId]);
    NSArray *attachmentIds = @[photo.uniqueId];
    XCTAssert([post.attachmentIds isEqualToString:[attachmentIds componentsJoinedByString:@"__"]]);
    XCTAssert([KPost findById:post.uniqueId].preview);
    XCTAssert(post.attachments.count == 1);
}

- (void)testLocationAttachment {
    KLocation *location = [[KLocation alloc] initWithAuthorId:[KAccountManager sharedManager].uniqueId location:[KAccountManager sharedManager].currentCoordinate];
    KPost *post = [[KPost alloc] initWithAuthorId:@"1"];
    [post addAttachment:location];
    XCTAssert(post.attachments.count == 1);
    XCTAssert(post.attachmentIds);
    XCTAssert([location.parentId isEqualToString:post.uniqueId]);
    XCTAssert([[post.attachmentIds componentsSeparatedByString:@"__"].firstObject isEqualToString:location.uniqueId]);
    XCTAssert(post.attachments.count == 1);
}


@end