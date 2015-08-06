//
//  KDevice.m
//  Key
//
//  Created by Brendan Farmer on 7/19/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KDevice.h"
#import "KStorageManager.h"

@implementation KDevice

- (instancetype)initWithUserId:(NSString *)userId deviceId:(NSString *)deviceId isCurrentDevice:(BOOL)isCurrentDevice {
    self = [super init];
    if(self) {
        _userId = userId;
        _deviceId = deviceId;
        _isCurrentDevice = isCurrentDevice;
    }
    
    return self;
}

+ (NSArray *)devicesForUserId:(NSString *)userId {
    return [[KStorageManager sharedManager] querySelectObjects:^NSArray *(FMDatabase *database) {
        FMResultSet *result = [database executeQuery:[NSString stringWithFormat:@"select * from %@ where user_id = :unique_id", [self tableName]] withParameterDictionary:@{@"unique_id" : userId}];
        NSMutableArray *devices = [[NSMutableArray alloc] init];
        while(result.next) {
            KDevice *device = [[KDevice alloc] initWithResultSetRow:result.resultDictionary];
            [devices addObject:device];
        }
        [result close];
        return [devices copy];
    }];
}

+ (KDevice *)addDeviceForUserId:(NSString *)userId deviceId:(NSString *)deviceId {
    KDevice *device = [self findByDictionary:@{@"userId" : userId, @"deviceId": deviceId}];
    if(device != nil) return device;
    KDevice *newDevice = [[self alloc] initWithUserId:userId deviceId:deviceId isCurrentDevice:NO];
    [newDevice save];
    return newDevice;
}

@end
