//
//  ProfileInfoTableViewCell.h
//  Twiddle
//
//  Created by Thomas Ring on 7/1/16.
//  Copyright © 2016 TRing. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProfileInfoTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UIButton *tweetsButton;
@property (strong, nonatomic) IBOutlet UIButton *followingButton;
@property (strong, nonatomic) IBOutlet UIButton *followersButton;

@end
