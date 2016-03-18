//
//  UIView+Messages.h
//  Key
//
//  Created by Brendan Farmer on 4/9/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Messages)

- (void)pinSubview:(UIView *)subview toEdge:(NSLayoutAttribute)attribute;
- (void)pinAllEdgesOfSubview:(UIView *)subview;

@end

