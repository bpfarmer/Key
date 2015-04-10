//
//  MessageCollectionViewLayoutAttributes.h
//  Key
//
//  Created by Brendan Farmer on 4/9/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MessageCollectionViewLayoutAttributes : UICollectionViewLayoutAttributes <NSCopying>

@property (strong, nonatomic) UIFont *messageBubbleFont;
@property (assign, nonatomic) CGFloat messageBubbleContainerViewWidth;
@property (assign, nonatomic) UIEdgeInsets textViewTextContainerInsets;
@property (assign, nonatomic) UIEdgeInsets textViewFrameInsets;
@property (assign, nonatomic) CGSize incomingAvatarViewSize;
@property (assign, nonatomic) CGSize outgoingAvatarViewSize;
@property (assign, nonatomic) CGFloat cellTopLabelHeight;
@property (assign, nonatomic) CGFloat messageBubbleTopLabelHeight;
@property (assign, nonatomic) CGFloat cellBottomLabelHeight;

@end
