//
//  OutgoingMessageCollectionViewCell.m
//  Key
//
//  Created by Brendan Farmer on 4/9/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "OutgoingMessageCollectionViewCell.h"

@implementation OutgoingMessageCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.messageBubbleTopLabel.textAlignment = NSTextAlignmentRight;
    self.cellBottomLabel.textAlignment = NSTextAlignmentRight;
}


@end
