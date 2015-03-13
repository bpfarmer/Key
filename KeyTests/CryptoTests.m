//
//  CryptoTests.m
//  FreeKey
//
//  Created by Brendan Farmer on 3/3/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "AES_CBC.h"

@interface CryptoTests : XCTestCase

@end

@implementation CryptoTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (NSData *)random128BitAESKey {
    unsigned char buf[16];
    arc4random_buf(buf, sizeof(buf));
    return [NSData dataWithBytes:buf length:sizeof(buf)];
}

/**
 *  Testing session initialization with a basic PrekeyWhisperMessage
 */

- (void)testEncryptionAndDecryption {
    NSString *originalMessage = @"Key is for sharing freely.";
    NSData *messageData = [originalMessage dataUsingEncoding:NSUTF8StringEncoding];
    NSData *key = [self random128BitAESKey];
    NSData *iv = [self random128BitAESKey];
    
    NSData *encryptedMessage = [AES_CBC encryptCBCMode:messageData
                                               withKey:key
                                                withIV:iv];
    
    NSData *decryptedMessage = [AES_CBC decryptCBCMode:encryptedMessage
                                               withKey:key
                                                withIV:iv];
    
    XCTAssert([messageData isEqual:decryptedMessage]);
}

@end