//
//  TweetImageTableViewCell.h
//  Twiddle
//
//  Created by Thomas Ring on 6/27/16.
//  Copyright © 2016 TRing. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TweetTextTableViewCell.h"

@interface TweetImageTableViewCell : TweetTextTableViewCell

@property (nonatomic, strong) IBOutlet UIImageView * contentImageView;

@end
