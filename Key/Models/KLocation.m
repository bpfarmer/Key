//
//  KLocation.m
//  Key
//
//  Created by Brendan Farmer on 7/2/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KLocation.h"

@implementation KLocation

- (instancetype)initWithUserUniqueId:(NSString *)userUniqueId location:(CLLocation *)location {
    self = [super init];
    
    if(self) {
        _userUniqueId = userUniqueId;
        _location     = location;
        [self setCaption];
    }
    return self;
}

- (instancetype)initWithUserUniqueId:(NSString *)userUniqueId location:(CLLocation *)location parentId:(NSString *)parentId address:(NSString *)address{
    self = [super init];
    
    if(self) {
        _userUniqueId = userUniqueId;
        _location     = location;
        _parentId     = parentId;
        _address      = address;
    }
    return self;
}

- (void)setCaption {
    CLGeocoder *ceo = [[CLGeocoder alloc]init];
    CLLocation *loc = [[CLLocation alloc]initWithCoordinate:self.location.coordinate altitude:self.location.altitude horizontalAccuracy:self.location.horizontalAccuracy verticalAccuracy:self.location.verticalAccuracy course:self.location.course speed:self.location.speed timestamp:self.location.timestamp];
    
    [ceo reverseGeocodeLocation:loc completionHandler:^(NSArray *placemarks, NSError *error) {
        CLPlacemark *placemark = [placemarks objectAtIndex:0];
        NSMutableArray *locationComponents = [NSMutableArray new];
        [[placemark.addressDictionary valueForKey:@"FormattedAddressLines"] componentsJoinedByString:@", "];
        
        if(placemark.name) [locationComponents addObject:placemark.name];
        NSArray *addressComponents = [[placemark.addressDictionary valueForKey:@"FormattedAddressLines"][1] componentsSeparatedByString:@" "];
        [locationComponents addObject:[NSString stringWithFormat:@"%@ %@", addressComponents[0], addressComponents[1]]];
        self.address = [locationComponents componentsJoinedByString:@", "];
    }];
}

- (NSString *)formattedAddress {
    return [self. address stringByReplacingOccurrencesOfString:@".," withString:@"."];
}

- (NSString *)shortAddress {
    NSArray *addressComponents = [self.address componentsSeparatedByString:@", "];
    return addressComponents.lastObject;
}


@end
