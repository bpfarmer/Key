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
    NSString *username = @"brendan";
    NSString *password = @"password2345";
    
    if([KUser isUsernameUnique:username]) {
        // Do any additional setup after loading the view, typically from a nib.
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^(void) {
            [KUser createUserWithUsername:username password:password inRealm:[RLMRealm defaultRealm]];
        });
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)encryptionCycleWithRSACryptor:(KRSACryptor *)RSACryptor
                              keyPair:(KRSACryptorKeyPair *)RSAKeyPair
                                error:(KError *)error
{
    NSString *cipherText =
    [RSACryptor encrypt:@"Key is great"
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
