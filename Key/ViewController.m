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

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^(void) {
        [self generateKeysExample];
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)generateKeysExample
{
    KError *error = [[KError alloc] init];
    KRSACryptor *RSACryptor = [[KRSACryptor alloc] init];
    
    KRSACryptorKeyPair *RSAKeyPair = [RSACryptor generateKeyPairWithKeyIdentifier:@"key_pair_tag"
                                                                             error:error];
    NSLog(@"Plain Text: \nKey is great");
    NSLog(@"Private Key:\n%@\n\nPublic Key:\n%@", RSAKeyPair.privateKey, RSAKeyPair.publicKey);
    
    [self encryptionCycleWithRSACryptor:RSACryptor
                                keyPair:RSAKeyPair
                                  error:error];
    
    KKeyPair *keyPair = [[KKeyPair alloc] init];
    keyPair.privateKey = RSAKeyPair.privateKey;
    keyPair.publicKey = RSAKeyPair.publicKey;
    keyPair.encryptionAlgorithm = @"RSA";
    RLMRealm *realm = [RLMRealm inMemoryRealmWithIdentifier:@"Test"];
    [realm beginWriteTransaction];
    [realm addObject:keyPair];
    [realm commitWriteTransaction];
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
