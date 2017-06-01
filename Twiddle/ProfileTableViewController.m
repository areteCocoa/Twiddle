//
//  ProfileTableViewController.m
//  Twiddle
//
//  Created by Thomas Ring on 7/1/16.
//  Copyright © 2016 TRing. All rights reserved.
//

#import "ProfileTableViewController.h"

#import "UserTimeline.h"
#import "TweetTextTableViewCell.h"
#import "TweetImageTableViewCell.h"
#import "ProfileHeaderTableViewCell.h"
#import "ProfileInfoTableViewCell.h"

static NSString * headerCellReuse = @"profile_header_image_cell";
static NSString * infoCellReuse = @"profile_header_info_cell";
static NSString * actionCellReuse = @"profile_action_cell";

const CGFloat dividerCellHeight = 20;

const CGFloat headerCellHeight = 280;
const CGFloat infoCellHeight = 60;
const CGFloat actionCellHeight = 40;
const CGFloat timelineHeaderHeight = 48;

typedef enum : NSUInteger {
	ProfileSectionHeader,
	ProfileSectionInfo,
	ProfileSectionAction,
	ProfileSectionTimeline,
} ProfileTableViewSection;

@interface ProfileTableViewController ()

@end

@implementation ProfileTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
	[self.tableView registerNib:[UINib nibWithNibName:@"TweetTextTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:textCellReuse];
	[self.tableView registerNib:[UINib nibWithNibName:@"TweetImageTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:imageCellReuse];
	
	[self.tableView registerNib:[UINib nibWithNibName:@"ProfileHeaderTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:headerCellReuse];
	[self.tableView registerNib:[UINib nibWithNibName:@"ProfileInfoTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:infoCellReuse];
	[self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:actionCellReuse];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (self.user == nil) {
		return 0;
	}
	
	if (section == ProfileSectionHeader) {
		return 1;
	} else if (section == ProfileSectionInfo) {
		return 1;
	} else if (section == ProfileSectionAction) {
		if ([self.user[@"following"] isEqual:@(YES)]) {
			return 3;
		} else {
			return 1;
		}
	} else if (section == ProfileSectionTimeline) {
		return 1;
	}
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell * cell;
	
	if (indexPath.section == ProfileSectionHeader) {
		cell = [tableView dequeueReusableCellWithIdentifier:headerCellReuse forIndexPath:indexPath];
		ProfileHeaderTableViewCell * c = (ProfileHeaderTableViewCell *)cell;
		
		UserTimeline * timeline = [UserTimeline sharedTimeline];
		
		// Download the profile banner
		// profile_banner_url
		if (c.coverPhotoImageView.image == nil) {
			[timeline getImageWithURL:self.user[@"profile_banner_url"] withCompletion:^(NSData *imageData, NSError *error) {
				if (error) {
					NSLog(@"%@", error.localizedDescription);
				} else {
					UIImage * image = [UIImage imageWithData: imageData];
					c.coverPhotoImageView.image = image;
					[self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
				}
			}];
		}
		
		// Get the avatar
		//c.avatarImageView
		if (c.avatarImageView.image == nil) {
			[timeline getImageWithURL:self.user[@"profile_image_url"] withCompletion:^(NSData *imageData, NSError *error) {
				if (error) {
					NSLog(@"%@", error.localizedDescription);
				} else {
					UIImage * image = [UIImage imageWithData: imageData];
					c.avatarImageView.image = image;
					[self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
				}
			}];
		}
		
		//c.verifiedImageView
		if ([self.user[@"verified"] isEqual: @(YES)]) {
			NSLog(@"THE USER IS VERIFIED");
		}
		
		c.handleLabel.text = self.user[@"name"];
		[c.handleLabel sizeToFit];
		
		c.usernameLabel.text = [NSString stringWithFormat:@"@%@", self.user[@"screen_name"]];
		[c.usernameLabel sizeToFit];
		
		// Format the creation date
		NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
		formatter.dateFormat = @"EEE MMM dd HH:mm:ss ZZZ yyyy";
		NSDate * date = [formatter dateFromString: self.user[@"created_at"]];
		formatter.dateFormat = @"MMM dd, yyyy";
		c.createdAtLabel.text = [formatter stringFromDate:date];
		
		//c.locationLabel.text
		NSString * location = self.user[@"location"];
		if (location != nil) {
			c.locationLabel.text = location;
		}
		
		c.descriptionLabel.text = self.user[@"description"];
		[c.descriptionLabel sizeToFit];
								
	} else if (indexPath.section == ProfileSectionInfo) {
		cell = [tableView dequeueReusableCellWithIdentifier:infoCellReuse forIndexPath:indexPath];
		ProfileInfoTableViewCell * c = (ProfileInfoTableViewCell *)cell;
		[c.tweetsButton setTitle:[NSString stringWithFormat:@"%@\nTweets", self.user[@"statuses_count"]] forState:UIControlStateNormal];
		[c.tweetsButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
		[c.followingButton setTitle:[NSString stringWithFormat:@"%@\nFollowing", self.user[@"friends_count"]] forState:UIControlStateNormal];
		[c.followingButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
		[c.followersButton setTitle:[NSString stringWithFormat:@"%@\nFollowers", self.user[@"followers_count"]] forState:UIControlStateNormal];
		[c.followersButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
	} else if (indexPath.section == ProfileSectionAction) {
		cell = [tableView dequeueReusableCellWithIdentifier:actionCellReuse forIndexPath:indexPath];
		
		// if we're following them we have three buttons: DM, Notifications and Unfollow
		if ([self.user[@"following"] isEqual:@(YES)]) {
			if (indexPath.row == 0) {
				cell.textLabel.text = @"Direct Message";
			} else if (indexPath.row == 1) {
				cell.textLabel.text = @"Notifications";
			} else if (indexPath.row == 2) {
				cell.textLabel.text = @"Unfollow";
			}
		} else {
			// We're not following them, we only have a single button
			// if the user is protected we must request to follow them first
			if ([self.user[@"protected"] isEqual:@(YES)]) {
				if ([self.user[@"follow_request_sent"] isEqual:@(YES)]) {
					cell.textLabel.text = @"Follow Request Sent";
				} else {
					cell.textLabel.text = @"Send Follow Request";
				}
			} else {
				cell.textLabel.text = @"Follow";
			}
		}
		
	} else if (indexPath.section == ProfileSectionTimeline) {
		cell = [tableView dequeueReusableCellWithIdentifier:actionCellReuse forIndexPath:indexPath];
		cell.textLabel.text = @"aSDF";
	}
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	if (section == 2) {
		UIView * view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, dividerCellHeight)];
		view.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
		return view;
	} else if (section == 3) {
		UIView * view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, timelineHeaderHeight)];
		view.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
		UISegmentedControl * segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Tweets", @"Media", @"Likes"]];
		segmentedControl.frame = CGRectMake(5, view.frame.size.height - segmentedControl.frame.size.height - 5, view.frame.size.width - 10, segmentedControl.frame.size.height);
		segmentedControl.selectedSegmentIndex = 0;
		[view addSubview:segmentedControl];
		
		return view;
	}
	return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	if (section == 2) {
		return dividerCellHeight;
	} else if (section == 3) {
		return timelineHeaderHeight;
	}
	return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == ProfileSectionHeader) {
		return headerCellHeight;
	} else if (indexPath.section == ProfileSectionInfo) {
		return infoCellHeight;
	} else if (indexPath.section == ProfileSectionAction) {
		return actionCellHeight;
	} else if (indexPath.section == ProfileSectionTimeline) {
		return actionCellHeight;
	}
	return 0;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
