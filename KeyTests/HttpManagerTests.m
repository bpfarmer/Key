//
//  HttpManagerTests.m
//  Key
//
//  Created by Brendan Farmer on 3/21/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "AES_CBC.h"
#import "HttpManager.h"

@interface HttpManagerTests : XCTestCase

@end

@implementation HttpManagerTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

/**
 *  Testing session initialization with a basic PrekeyWhisperMessage
 */

- (void)testBase64Decoding {
    NSDictionary *responseObject = @{
                                     @"pre_key" : @{
                                             @"deviceId" : @"1",
                                             @"identityKey" : @"AQQzwTZ/Ldj3NwIiC1PEKtRBwprTJaCFP2252NKpLCw=",
                                             @"signedPreKeyId" : @"ce6aeabafc0c0841_1426942740.569203_1",
                                             @"signedPreKeyPublic" : @"bgAnFSqtlMOxUh3Pu9sSJnlPAuJym9j6BZG9ZOqvoGw=",
                                             @"signedPreKeySignature" : @"Kf4h13InS2IngqCXepqQgnatRz6rDi++hLcoseUVSAT4AOi8X8DP/rxmyjBgTcVx2nVsbhq1wmRsQyZzXNyXjA==",
                                             @"userId" : @"ce6aeabafc0c0841"},
                                     @"status" : @"SUCCESS",
                                     @"user"   : @{
                                             @"createdAt" : @"2015-03-21T12:59:00.087Z",
                                             @"publicKey" : @"AQQzwTZ/Ldj3NwIiC1PEKtRBwprTJaCFP2252NKpLCw=",
                                             @"uniqueId" : @"ce6aeabafc0c0841",
                                             @"username" : @"rob"}};

    NSDictionary *decodedDictionary = [[HttpManager sharedManager] base64DecodedDictionary:responseObject];
    
    XCTAssert([decodedDictionary[@"pre_key"][@"identityKey"] isKindOfClass:[NSData class]]);
    XCTAssert([decodedDictionary[@"pre_key"][@"signedPreKeyPublic"] isKindOfClass:[NSData class]]);
    XCTAssert([decodedDictionary[@"pre_key"][@"signedPreKeySignature"] isKindOfClass:[NSData class]]);
    XCTAssert([decodedDictionary[@"user"][@"publicKey"] isKindOfClass:[NSData class]]);
}

@end