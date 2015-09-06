//
//  KLocationTests.m
//  Key
//
//  Created by Brendan Farmer on 9/4/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "KLocation.h"
#import "KStorageManager.h"
#import "KAccountManager.h"
#import "CollapsingFutures.h"

@interface KLocationTests : XCTestCase

@end

@implementation KLocationTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testInit {
    CLLocation *locationActual = [[CLLocation alloc] initWithLatitude:-56.6462520 longitude:-56.6462520];
    KLocation *location = [[KLocation alloc] initWithAuthorId:@"1" location:locationActual];
    XCTAssert([location.authorId isEqualToString:@"1"]);
    XCTAssert(location.location.coordinate.latitude == locationActual.coordinate.latitude);
    XCTAssert(location.uniqueId);
    location = [[KLocation alloc] initWithUniqueId:@"KLocation_1" authorId:@"1" location:locationActual parentId:@"KPost_1" address:@"Some Address"];
    XCTAssert([location.uniqueId isEqualToString:@"KLocation_1"]);
    XCTAssert([location.authorId isEqualToString:@"1"]);
    XCTAssert(location.location.coordinate.latitude == locationActual.coordinate.latitude);
    XCTAssert([location.parentId isEqualToString:@"KPost_1"]);
    XCTAssert([location.address isEqualToString:@"Some Address"]);
}

- (void)testCaption {
    XCTestExpectation *locationExpectation = [self expectationWithDescription:@"Waiting for geocoding"];
    __block CLLocation *locationActual;
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    NSString *address = @"297 Covey Rd, Westford, VT";
    [geocoder geocodeAddressString:address completionHandler:^(NSArray *placemarks, NSError *error) {
        CLPlacemark *placemark = placemarks.firstObject;
        locationActual = [[CLLocation alloc] initWithLatitude:placemark.location.coordinate.latitude longitude:placemark.location.coordinate.longitude];
        [[KLocation addressFromLocation:locationActual] thenDo:^(NSString *returnedAddress) {
            XCTAssert([address isEqualToString:returnedAddress]);
            [locationExpectation fulfill];
        }];

    }];
    
    [self waitForExpectationsWithTimeout:3 handler:nil];
}

- (void)testFormattedAddress {
    KLocation *location = [[KLocation alloc] initWithUniqueId:nil authorId:nil location:nil parentId:nil address:@"Apple Inc., Test Road, TC TS"];
    XCTAssert([location.formattedAddress isEqualToString:@"Apple Inc. Test Road, TC TS"]);
}

- (void)testShortAddress {
    KLocation *location = [[KLocation alloc] initWithUniqueId:nil authorId:nil location:nil parentId:nil address:@"Apple Inc., Test Road, TC TS"];
    XCTAssert([location.shortAddress isEqualToString:@"Test Road, TC TS"]);
}


@end
