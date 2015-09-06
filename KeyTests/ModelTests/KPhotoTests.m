//
//  KPhotoTests.m
//  Key
//
//  Created by Brendan Farmer on 9/4/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "KPhoto.h"
#import "KStorageManager.h"
#import "KAccountManager.h"
#import "CollapsingFutures.h"

@interface KPhotoTests : XCTestCase

@end

@implementation KPhotoTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testInit {
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"beach" ofType:@"jpg"];
    NSData *img = [NSData dataWithContentsOfFile:imagePath];
    KPhoto *photo = [[KPhoto alloc] initWithMedia:img];
    XCTAssert(photo.media);
    [photo save];
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    NSString *filePath = [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent:photo.uniqueId]];
    XCTAssert([NSData dataWithContentsOfFile:filePath].length > 0);
    XCTAssert([KPhoto findById:photo.uniqueId].media);
    photo = [[KPhoto alloc] initWithUniqueId:@"KPhoto_1" media:img parentId:@"KPost_1"];
    XCTAssert([photo.uniqueId isEqualToString:@"KPhoto_1"]);
    XCTAssert(photo.media);
    XCTAssert([photo.parentId isEqualToString:@"KPost_1"]);
    [photo save];
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = [dirPaths objectAtIndex:0];
    filePath = [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent:photo.uniqueId]];
    XCTAssert([NSData dataWithContentsOfFile:filePath].length > 0);
}

- (void)testUnsavedPropertyList {
    NSArray *array = @[@"media"];
    XCTAssert([[KPhoto unsavedPropertyList] isEqualToArray:array]);
}

@end
