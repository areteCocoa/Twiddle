//
//  TimelineTableViewController.m
//  Twiddle
//
//  Created by Thomas Ring on 6/19/16.
//  Copyright © 2016 TRing. All rights reserved.
//

#import "TimelineTableViewController.h"

#import "UserTimeline.h"
#import "TweetTextTableViewCell.h"

static NSString * textCellReuse = @"text_cell";
static NSString * imageCellReuse = @"image_cell";

static CGFloat textCellHeight = 120;
static CGFloat imageCellHeight = 150;

@interface TimelineTableViewController () <UserTimelineDelegate>

@property (nonatomic, retain) UserTimeline * timeline;

@property (nonatomic, retain) NSMutableDictionary<NSNumber *, UIImage *> * imageCache;

@end

@implementation TimelineTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blueColor];
    
    self.imageCache = [[NSMutableDictionary alloc] init];
    
    self.timeline = [[UserTimeline alloc] init];
    self.timeline.delegate = self;
    
    [self.timeline login];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.timeline.tweets.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return textCellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:textCellReuse forIndexPath:indexPath];
    
    // Configure the cell...
    NSDictionary * tweet = self.timeline.tweets[indexPath.row];
    NSNumber * userID = tweet[@"user"][@"id"];
    
    TweetTextTableViewCell * textCell = (TweetTextTableViewCell *)cell;
    
    // Setup properties of views
    [textCell.tweetTextView setFont:[UIFont systemFontOfSize: 17.0]];
    
    // Setup properties
    textCell.usernameLabel.text = tweet[@"user"][@"name"];
    textCell.tweetTextView.text = tweet[@"text"];
    
    UIImage * userAvatarImage = [self.imageCache objectForKey: userID];
    if(userAvatarImage == nil) {
        NSLog(@"Tweet cell has all the information but the profile image is not downloaded!");
        [self.timeline getProfilePictureForUserID: tweet[@"user"][@"id"]];
    } else {
        NSLog(@"WE DID IT!");
        textCell.userAvatarImageView.image = [self.imageCache objectForKey:userID];
    }
    
    return cell;
}

#pragma mark - UserTimelineDelegate

- (void)timeline:(UserTimeline *)timeline didFinishGettingTweets:(NSArray *)tweets {
    [self.tableView reloadData];
}

- (void)timeline:(UserTimeline *)timeline didLoginWithError:(NSError *)error {
    if (!error) {
        [timeline getTimeline];
    }
}

- (void)timeline:(UserTimeline *)timeline didFinishDownloadingProfileImageData:(NSData *)imageData forUserID:(NSNumber *)userID {
    NSLog(@"VC received image data for ID %@", userID);
    
    UIImage * image = [UIImage imageWithData:imageData];
    
    [self.imageCache setObject:image forKey:userID];
    
    NSLog(@"Image data converted to UIImage and cached");
    
    dispatch_async(dispatch_get_main_queue(), ^{ // Make sure it happens on the main thread
        [self.tableView reloadData];
    });
}

#pragma mark - IBActions

- (IBAction)refresh: (UIRefreshControl *)sender {
    NSLog(@"Refreshing");
    [sender endRefreshing];
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
