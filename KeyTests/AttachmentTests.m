//
//  AttachmentTests.h
//  Key
//
//  Created by Brendan Farmer on 7/22/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "FreeKey.h"
#import "KUser.h"
#import "KStorageManager.h"
#import "KPhoto.h"
#import "AttachmentKey.h"

@interface AttachmentTests : XCTestCase

@end

@implementation AttachmentTests

- (void)setUp {
    [super setUp];
    [[KStorageManager sharedManager] setDatabaseWithName:@"testDB"];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testSession {
    KPhoto *photo = [[KPhoto alloc] initWithMedia:nil ephemeral:NO];
    AttachmentKey *attachmentKey = [[AttachmentKey alloc] init];
    [attachmentKey save];
    KUser *localUser  = [[KUser alloc] initWithUniqueId:@"1"];
    [localUser save];
    [localUser setCurrentDevice];
    KUser *remoteUser = [[KUser alloc] initWithUniqueId:@"2"];
    [remoteUser save];
    [remoteUser addDeviceId:@"2"];
    NSData *cipherText = [attachmentKey encryptObject:photo];
    NSLog(@"CIPHER TEXT: %@", cipherText);
    [FreeKey sendAttachmentWithCipherText:cipherText attachmentKey:attachmentKey localUser:localUser remoteUser:remoteUser];
}


@end
