//
//  KDeviceTests.m
//  Key
//
//  Created by Brendan Farmer on 8/10/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "KUser.h"
#import "KDevice.h"
#import "KStorageManager.h"
#import "KAccountManager.h"
#import "KStorageSchema.h"
#import "CollapsingFutures.h"
#import "KTestHelper.h"

@interface KDeviceTests : XCTestCase

@end

@implementation KDeviceTests

- (void)setUp {
    [super setUp];
    [KTestHelper setup];
}

- (void)tearDown {
    [super tearDown];
    [KTestHelper tearDown];
}

- (void)testDropTable {
    [KDevice addDeviceForUserId:@"1" deviceId:@"1"];
    [KDevice addDeviceForUserId:@"1" deviceId:@"2"];
    [KDevice addDeviceForUserId:@"2" deviceId:@"3"];
    [KDevice addDeviceForUserId:@"2" deviceId:@"4"];
    [KDevice addDeviceForUserId:@"3" deviceId:@"5"];
    NSArray *devices = [KDevice devicesForUserIds:@[@"1", @"2"]];
    XCTAssert(devices.count == 4);
    devices = [KDevice devicesForUserIds:@[@"1", @"2", @"3"]];
    XCTAssert(devices.count == 5);
}

@end