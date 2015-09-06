//
//  KLocation.m
//  Key
//
//  Created by Brendan Farmer on 7/2/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KLocation.h"
#import "KPost.h"
#import "CollapsingFutures.h"

@implementation KLocation

- (instancetype)initWithAuthorId:(NSString *)authorId location:(CLLocation *)location {
    self = [super initWithUniqueId:[KLocation generateUniqueIdWithClass]];
    
    if(self) {
        _authorId     = authorId;
        _location     = location;
    }
    return self;
}

- (instancetype)initWithUniqueId:(NSString *)uniqueId authorId:(NSString *)authorId location:(CLLocation *)location parentId:(NSString *)parentId address:(NSString *)address {
    self = [super initWithUniqueId:uniqueId];
    
    if(self) {
        _authorId     = authorId;
        _location     = location;
        _parentId     = parentId;
        _address      = address;
    }
    return self;
}

+ (TOCFuture *)addressFromLocation:(CLLocation *)location {
    TOCFutureSource *futureAddress = [TOCFutureSource new];
    CLGeocoder *ceo = [[CLGeocoder alloc] init];
    [ceo reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        CLPlacemark *placemark = [placemarks objectAtIndex:0];
        NSMutableArray *locationComponents = [NSMutableArray new];
        if(placemark.name) [locationComponents addObject:placemark.name];
        NSArray *addressComponents;
        if(((NSArray *)[placemark.addressDictionary valueForKey:@"FormattedAddressLines"]).count > 1 ) addressComponents = [[placemark.addressDictionary valueForKey:@"FormattedAddressLines"][1] componentsSeparatedByString:@" "];
        if(addressComponents.count > 1) [locationComponents addObject:[NSString stringWithFormat:@"%@ %@", addressComponents[0], addressComponents[1]]];
        [futureAddress trySetResult:[locationComponents componentsJoinedByString:@", "]];
    }];
    
    return futureAddress.future;
}

- (NSString *)formattedAddress {
    return [self.address stringByReplacingOccurrencesOfString:@".," withString:@"."];
}

- (NSString *)shortAddress {
    NSArray *addressComponents = [self.address componentsSeparatedByString:@", "];
    NSMutableArray *shortAddressComponents = [NSMutableArray new];
    for(NSString *address in [addressComponents reverseObjectEnumerator]) if(shortAddressComponents.count < 2) [shortAddressComponents addObject:address];
    return [NSString stringWithFormat:@"%@, %@", shortAddressComponents.lastObject, shortAddressComponents.firstObject];
}

- (KPost *)post {
    return [KPost findById:self.parentId];
}

@end
