//
//  SubtitleTableViewCell.m
//  Key
//
//  Created by Brendan Farmer on 8/13/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "SubtitleTableViewCell.h"

@implementation SubtitleTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    return self;
}

- (void)setRightDetailText:(NSString *)text {
    UILabel *rightLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.textLabel.frame.size.width + 180.0, 0, 70.0, 20)];
    rightLabel.text = text;
    rightLabel.textAlignment = NSTextAlignmentRight;
    rightLabel.font = [UIFont fontWithName:self.detailTextLabel.font.fontName size:8];
    [self.textLabel addSubview:rightLabel];
}

- (void)addUnreadImage {
    UIImageView *unreadImage = [[UIImageView alloc] initWithImage:[self unreadImage]];
    unreadImage.frame = CGRectMake(0, 30, 7, 7);
    [self.contentView addSubview:unreadImage];
}

- (UIImage *)unreadImage {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(7.f, 7.f), NO, 0.0f);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    
    CGRect rect = CGRectMake(0, 0, 7, 7);
    
    CGContextSetFillColorWithColor(ctx, [[UIView alloc] init].tintColor.CGColor);
    CGContextFillEllipseInRect(ctx, rect);
    
    CGContextRestoreGState(ctx);
    UIImage *blueCircle = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return blueCircle;
}


@end
