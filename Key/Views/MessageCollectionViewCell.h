//
//  MessageCollectionViewCell.h
//  Key
//
//  Created by Brendan Farmer on 4/9/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MessageCollectionViewCell;

@protocol MessageCollectionViewCellDelegate <NSObject>

@required

- (void)messagesCollectionViewCellDidTapAvatar:(MessageCollectionViewCell *)cell;
- (void)messagesCollectionViewCellDidTapMessageBubble:(MessageCollectionViewCell *)cell;
- (void)messagesCollectionViewCellDidTapCell:(MessageCollectionViewCell *)cell atPosition:(CGPoint)position;

@end

@interface MessageCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) id <MessageCollectionViewCellDelegate> delegate;
@property (weak, nonatomic, readonly) UILabel *cellTopLabel;
@property (weak, nonatomic, readonly) UILabel *messageBubbleTopLabel;
@property (weak, nonatomic, readonly) UILabel *cellBottomLabel;
@property (weak, nonatomic, readonly) UITextView *textView;
@property (weak, nonatomic, readonly) UIImageView *messageBubbleImageView;
@property (weak, nonatomic, readonly) UIView *messageBubbleContainerView;
@property (weak, nonatomic, readonly) UIImageView *avatarImageView;
@property (weak, nonatomic, readonly) UIView *avatarContainerView;
@property (weak, nonatomic) UIView *mediaView;
@property (weak, nonatomic, readonly) UITapGestureRecognizer *tapGestureRecognizer;

#pragma mark - Class methods

+ (UINib *)nib;
+ (NSString *)cellReuseIdentifier;
+ (NSString *)mediaCellReuseIdentifier;


@end
