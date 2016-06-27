//
//  TweetTextTableViewCell.h
//  Twiddle
//
//  Created by Thomas Ring on 6/20/16.
//  Copyright © 2016 TRing. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TweetTextTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *usernameLabel;
@property (strong, nonatomic) IBOutlet UIImageView *userAvatarImageView;
@property (strong, nonatomic) IBOutlet UITextView *tweetTextView;

@property (nonatomic, strong) IBOutlet UILabel * createdDateLabel;
@property (nonatomic, strong) IBOutlet UILabel * retweetCountLabel;
@property (nonatomic, strong) IBOutlet UILabel * favoritesCountLabel;

@property (nonatomic, strong) IBOutlet UILabel * retweetedLabel;
@property (nonatomic, strong) IBOutlet UILabel * favoritedLabel;

@end
