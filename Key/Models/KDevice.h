//
//  KDevice.h
//  Key
//
//  Created by Brendan Farmer on 7/19/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KDatabaseObject.h"

@interface KDevice : KDatabaseObject

@property (nonatomic) NSString *userId;
@property (nonatomic) NSString *deviceId;
@property (nonatomic) BOOL isCurrentDevice;

- (instancetype)initWithUserId:(NSString *)userId deviceId:(NSString *)deviceId isCurrentDevice:(BOOL)isCurrentDevice;

@end
