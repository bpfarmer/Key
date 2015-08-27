//
//  KStorageSchema.m
//  Key
//
//  Created by Brendan Farmer on 7/9/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KStorageManager.h"
#import "KStorageSchema.h"
#import "KUser.h"
#import "KMessage.h"
#import "KThread.h"
#import "KGroup.h"
#import "Session.h"
#import "RootChain.h"
#import "SessionState.h"
#import "KOutgoingObject.h"
#import "KPhoto.h"
#import "KLocation.h"
#import "PreKey.h"
#import "PreKeyExchange.h"
#import "RootChain.h"
#import "EncryptedMessage.h"
#import "KPost.h"
#import "KDevice.h"
#import "AttachmentKey.h"
#import "ObjectRecipient.h"

@implementation KStorageSchema

+ (void)createTables {
    [KUser createTable];
    [KMessage createTable];
    [KThread createTable];
    [KGroup createTable];
    [Session createTable];
    [SessionState createTable];
    [RootChain createTable];
    [KOutgoingObject createTable];
    [KPhoto createTable];
    [KLocation createTable];
    [PreKey createTable];
    [PreKeyExchange createTable];
    [RootChain createTable];
    [EncryptedMessage createTable];
    [KPost createTable];
    [KDevice createTable];
    [AttachmentKey createTable];
    [ObjectRecipient createTable];
    
    [self updateSchema];
}

+ (void)dropTables {
    [KUser dropTable];
    [KMessage dropTable];
    [KThread dropTable];
    [KGroup dropTable];
    [Session dropTable];
    [SessionState dropTable];
    [RootChain dropTable];
    [KOutgoingObject dropTable];
    [KPhoto dropTable];
    [KLocation dropTable];
    [PreKeyExchange dropTable];
    [PreKey dropTable];
    [EncryptedMessage dropTable];
    [KPost dropTable];
    [KDevice dropTable];
    [AttachmentKey dropTable];
}

+ (void)updateSchema {
    [self addColumn:@"last_message_at" toTable:[KThread tableName] withType:@"double"];
    [self addColumn:@"updated_at" toTable:[KThread tableName] withType:@"double"];
    [self addColumn:@"attachment_count" toTable:[KPost tableName] withType:@"integer"];
    [self addColumn:@"thread_id" toTable:[KPost tableName] withType:@"string"];
    [self addColumn:@"read_at" toTable:[KMessage tableName] withType:@"double"];
    [self addColumn:@"read_at" toTable:[KPost tableName] withType:@"double"];
    [self addColumn:@"author_id" toTable:[KLocation tableName] withType:@"string"];
}

+ (void)addColumn:(NSString *)column toTable:(NSString *)table withType:(NSString *)type {
    [[KStorageManager sharedManager].queue inDatabase:^(FMDatabase *db) {
         if(![db columnExists:column inTableWithName:table]) {
            [db executeUpdate:[NSString stringWithFormat:@"alter table %@ add column %@ %@", table, column, type]];
        
        }
    }];
}


@end
