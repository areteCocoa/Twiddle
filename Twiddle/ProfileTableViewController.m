//
//  ProfileTableViewController.m
//  Twiddle
//
//  Created by Thomas Ring on 7/1/16.
//  Copyright © 2016 TRing. All rights reserved.
//

#import "ProfileTableViewController.h"

#import "ProfileHeaderTableViewCell.h"
#import "ProfileInfoTableViewCell.h"

static NSString * headerCellReuse = @"profile_header_image_cell";
static NSString * infoCellReuse = @"profile_header_info_cell";
static NSString * actionCellReuse = @"profile_action_cell";
static NSString * timelineHeaderCellReuse = @"profile_timeline_type_cell";

const CGFloat headerCellHeight = 255;
const CGFloat infoCellHeight = 60;
const CGFloat actionCellHeight = 40;
const CGFloat timelineHeaderHeight = 28;

typedef enum : NSUInteger {
	ProfileSectionHeader,
	ProfileSectionInfo,
	ProfileSectionAction,
	ProfileSectionTimelineHeaderSection,
} ProfileTableViewSection;

@interface ProfileTableViewController ()

@end

@implementation ProfileTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
		
	} else if (section == ProfileSectionTimelineHeaderSection) {
		
	}
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell * cell;
	
	if (indexPath.section == ProfileSectionHeader) {
		cell = [tableView dequeueReusableCellWithIdentifier:headerCellReuse forIndexPath:indexPath];
		ProfileHeaderTableViewCell * c = (ProfileHeaderTableViewCell *)cell;
		
		//c.coverPhotoImageView
		//c.avatarImageView
		//c.verifiedImageView
		c.handleLabel.text = self.user[@"name"];
		c.usernameLabel.text = [NSString stringWithFormat:@"@%@", self.user[@"screen_name"]];
		//c.createdAtLabel.text
		//c.locationLabel.text
		c.descriptionLabel.text = self.user[@"description"];
								
	} else if (indexPath.section == ProfileSectionInfo) {
		cell = [tableView dequeueReusableCellWithIdentifier:infoCellReuse forIndexPath:indexPath];
		ProfileInfoTableViewCell * c = (ProfileInfoTableViewCell *)cell;
	} else if (indexPath.section == ProfileSectionAction) {
		cell = [tableView dequeueReusableCellWithIdentifier:actionCellReuse forIndexPath:indexPath];
	} else if (indexPath.section == ProfileSectionTimelineHeaderSection) {
		cell = [tableView dequeueReusableCellWithIdentifier:timelineHeaderCellReuse forIndexPath:indexPath];
	}
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == ProfileSectionHeader) {
		return headerCellHeight;
	} else if (indexPath.section == ProfileSectionInfo) {
		return infoCellHeight;
	} else if (indexPath.section == ProfileSectionAction) {
		return actionCellHeight;
	} else if (indexPath.section == ProfileSectionTimelineHeaderSection) {
		return timelineHeaderHeight;
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
