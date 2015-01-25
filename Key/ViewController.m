//
//  ViewController.m
//  Key
//
//  Created by Brendan Farmer on 1/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "ViewController.h"
#import "KRSACryptor.h"
#import "KRSACryptorKeyPair.h"
#import "KError.h"
#import "KKeyPair.h"
#import "KUser.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *username = @"brendan2";
    NSString *password = @"password2345";
    KUser *user = [[KUser alloc] init];
    [user registerUsername:username password:password];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)encryptionCycleWithRSACryptor:(KRSACryptor *)RSACryptor
                              keyPair:(KRSACryptorKeyPair *)RSAKeyPair
                                error:(KError *)error
{
    NSString *cipherText = [RSACryptor encrypt:@"Key is great"
                                           key:RSAKeyPair.publicKey
                                         error:error];
    
    NSLog(@"Cipher Text:\n%@", cipherText);
    
    NSString *recoveredText =
    [RSACryptor decrypt:cipherText
                    key:RSAKeyPair.privateKey
                  error:error];
    
    NSLog(@"Recovered Text:\n%@", recoveredText);
}

@end
