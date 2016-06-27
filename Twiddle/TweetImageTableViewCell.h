//
//  TweetImageTableViewCell.h
//  Twiddle
//
//  Created by Thomas Ring on 6/27/16.
//  Copyright © 2016 TRing. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TweetImageTableViewCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UIImageView * contentImageView;

@property (nonatomic, strong) IBOutlet UILabel * createdAtLabel;

@property (nonatomic, strong) IBOutlet UILabel * nameLabel;

@end
