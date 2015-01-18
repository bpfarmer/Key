//
//  KGroup.h
//  Key
//
//  Created by Brendan Farmer on 1/17/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Realm/Realm.h>

@interface KGroup : RLMObject

@property NSString *publicId;
@property NSString *name;
@property (readonly) NSArray *users;


@end

// This protocol enables typed collections. i.e.:
// RLMArray<KGroup>
RLM_ARRAY_TYPE(KGroup)
