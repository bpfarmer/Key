//
//  DismissAndPresentProtocol.h
//  Key
//
//  Created by Brendan Farmer on 7/12/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KThread;

@protocol DismissAndPresentProtocol <NSObject>

- (void)dismissAndPresentViewController:(UIViewController *)viewController;

@end
