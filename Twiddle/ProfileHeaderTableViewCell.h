//
//  ProfileHeaderTableViewCell.h
//  Twiddle
//
//  Created by Thomas Ring on 7/1/16.
//  Copyright © 2016 TRing. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProfileHeaderTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIImageView *coverPhotoImageView;
@property (strong, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (strong, nonatomic) IBOutlet UIImageView *verifiedImageView;
@property (strong, nonatomic) IBOutlet UILabel *handleLabel;
@property (strong, nonatomic) IBOutlet UILabel *usernameLabel;
@property (strong, nonatomic) IBOutlet UILabel *createdAtLabel;
@property (strong, nonatomic) IBOutlet UILabel *locationLabel;
@property (strong, nonatomic) IBOutlet UILabel *descriptionLabel;

@end
