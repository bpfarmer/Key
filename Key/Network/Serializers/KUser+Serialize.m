//
//  KUser+Serialize.m
//  Key
//
//  Created by Brendan Farmer on 3/14/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KUser+Serialize.h"
#import "IdentityKey.h"
#import "KStorageManager.h"
#import "CollapsingFutures.h"

#define kCoderUniqueId @"unique_id"
#define kCoderUsername @"username"
#define kCoderPasswordCrypt @"password_crypt"
#define kCoderPasswordSalt @"password_salt"
#define kCoderPublicKey @"public_key"
#define kCoderIdentityKey @"identity_key"
#define kCoderPreKey @"pre_key"
#define kCoderLocalUser @"local_user"

@implementation KUser(Serialize)

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    return [self initWithUniqueId:[aDecoder decodeObjectOfClass:[NSString class] forKey:kCoderUniqueId]
                         username:[aDecoder decodeObjectOfClass:[NSString class] forKey:kCoderUsername]
                    passwordCrypt:[aDecoder decodeObjectOfClass:[NSData class] forKey:kCoderPasswordCrypt]
                     passwordSalt:[aDecoder decodeObjectOfClass:[NSData class] forKey:kCoderPasswordSalt]
                      identityKey:[aDecoder decodeObjectOfClass:[IdentityKey class] forKey:kCoderIdentityKey]
                        publicKey:[aDecoder decodeObjectOfClass:[NSData class] forKey:kCoderPublicKey]];
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.uniqueId forKey:kCoderUniqueId];
    [aCoder encodeObject:self.username forKey:kCoderUsername];
    [aCoder encodeObject:self.passwordCrypt forKey:kCoderPasswordCrypt];
    [aCoder encodeObject:self.passwordSalt forKey:kCoderPasswordSalt];
    [aCoder encodeObject:self.identityKey forKey:kCoderIdentityKey];
    [aCoder encodeObject:self.publicKey forKey:kCoderPublicKey];
}

+ (void)createTable {
    NSString *createTableSQL = [NSString stringWithFormat:@"create table %@ (unique_id text primary key not null, username text, password_crypt blob, password_salt blob, identity_key blob, public_key blob);", [self tableName]];
    [[KStorageManager sharedManager] queryUpdate:createTableSQL parameters:nil];
}

- (void)save {
    if(self.uniqueId) {
        NSString *insertOrReplaceSQL = [NSString stringWithFormat:@"insert or replace into %@ (unique_id, username, password_crypt, password_salt, identity_key, public_key) values(:unique_id, :username, :password_crypt, :password_salt, :identity_key, :public_key)", [self.class tableName]];
        
        NSMutableDictionary *userDictionary = [[NSMutableDictionary alloc] init];
        [userDictionary setObject:self.uniqueId forKey:@"unique_id"];
        [userDictionary setObject:self.username forKey:@"username"];
        [userDictionary setObject:self.passwordCrypt forKey:@"password_crypt"];
        [userDictionary setObject:]
        
        [NSDictionary dictionaryWithObjectsAndKeys:self.uniqueId, @"unique_id", self.username, @"username", self.passwordCrypt, @"password_crypt", self.passwordSalt, @"password_salt", self.identityKey, @"identity_key", self.publicKey, @"public_key", nil];
        [[KStorageManager sharedManager] queryUpdate:insertOrReplaceSQL parameters:userDictionary];
    }
}

+ (TOCFuture *)all {
    TOCFutureSource *resultSource = [TOCFutureSource new];
    NSString *findAllSQL = [NSString stringWithFormat:@"select * from %@", [self.class tableName]];
    [resultSource trySetResult:[[KStorageManager sharedManager] querySelect:findAllSQL parameters:nil]];
    return resultSource.future;
}

- (void)remove {
    if(self.uniqueId) {
        NSString *deleteSQL = [NSString stringWithFormat:@"delete from %@ where unique_id = :unique_id", [self.class tableName]];
        NSDictionary *userDictionary = [NSDictionary dictionaryWithObjectsAndKeys:self.uniqueId, @"unique_id", nil];
        [[KStorageManager sharedManager] queryUpdate:deleteSQL parameters:userDictionary];
    }
}

@end
