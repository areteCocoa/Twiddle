//
//  TweetImageTableViewCell.m
//  Twiddle
//
//  Created by Thomas Ring on 6/27/16.
//  Copyright © 2016 TRing. All rights reserved.
//

#import "TweetImageTableViewCell.h"

@interface TweetImageTableViewCell()

@property (nonatomic) IBInspectable CGFloat textViewInsetX;

@property (nonatomic) IBInspectable CGFloat textViewInsetY;

@end

@implementation TweetImageTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}



@end
