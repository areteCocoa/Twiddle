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
#import "TweetImageTableViewCell.h"

static NSString * textCellReuse = @"text_cell";
static NSString * imageCellReuse = @"image_cell";
static NSString * loadMoreReuse = @"load_more_cell";

static CGFloat textCellHeight = 120;
static CGFloat imageCellHeight = 150;
static CGFloat loadMoreCellHeight = 40;

typedef enum : NSUInteger {
    TweetsSection,
    LoadMoreSection,
} TimelineTableViewControllerSection;

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

- (void)loadMoreTweets {
    [self.timeline getMoreTimeline];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == TweetsSection) {
        return self.timeline.tweets.count;
    } else if (section == LoadMoreSection) {
        if (self.timeline.tweets.count == 0) {
            return 0;
        }
        return 1;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == TweetsSection) {
		if (self.timeline.tweets.count == 0 || self.timeline.tweets.count < indexPath.row) {
			// We don't have data for this cell yet, return placeholder height
			return textCellHeight;
		} else {
			// We actually have data, time to figure out it's type and height
			NSDictionary * tweet = self.timeline.tweets[indexPath.row];
			if ([[tweet[@"entities"][@"media"] firstObject][@"type"] isEqualToString:@"photo"]) {
				// It is an image and we need to calculate the height given the screen width
				NSDictionary * imageSizes = [tweet[@"entities"][@"media"] firstObject][@"sizes"];
				NSNumber * imageHeight = imageSizes[@"large"][@"w"], * imageWidth = imageSizes[@"large"][@"w"];
				NSLog(@"Image has height %@", imageHeight);
				
				// use placeholder as a test for now
				imageWidth = @1200;
				imageHeight = @742;
				
				CGFloat imageWidthFloat = [imageWidth floatValue], imageHeightFloat = [imageHeight floatValue];
				
				CGFloat cellWidth = self.tableView.frame.size.width;
				CGFloat cellHeight = (cellWidth * imageHeightFloat) / imageWidthFloat;
				
				return cellHeight;
			} else {
				// It is a text cell and we can return the placeholder for now
				return textCellHeight;
			}
		}
		
        return textCellHeight;
    } else if (indexPath.section == LoadMoreSection) {
        return loadMoreCellHeight;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == TweetsSection) {
		UITableViewCell * cell;
		
		// Fetch the data first
		NSDictionary * tweet = self.timeline.tweets[indexPath.row];
		NSNumber * userID = tweet[@"user"][@"id"];
		
		// Figure out what kind of tweet we have -- text or image or link
		if ([[tweet[@"entities"][@"media"] firstObject][@"type"] isEqualToString:@"photo"]) {
			// We need an image cell
			cell = [tableView dequeueReusableCellWithIdentifier:imageCellReuse forIndexPath:indexPath];
			
			TweetImageTableViewCell * imageCell = (TweetImageTableViewCell *)cell;
			
			// Load image
			UIImage * tempImage = [UIImage imageNamed:@"image_placeholder"];
			
			imageCell.contentImageView.image = tempImage;
		} else {
			// We need a text cell
			cell = [tableView dequeueReusableCellWithIdentifier:textCellReuse forIndexPath:indexPath];
			
			// Configure the cell...
			
			
			TweetTextTableViewCell * textCell = (TweetTextTableViewCell *)cell;
			
			// Setup properties
			textCell.usernameLabel.text = tweet[@"user"][@"name"];
			textCell.tweetTextView.text = tweet[@"text"];
			
			textCell.createdDateLabel.text = tweet[@"created_at"];
			
			textCell.favoritedLabel.text = [tweet[@"favorited"]  isEqual: @(YES)] ? @"F" : @"NF";
			textCell.favoritesCountLabel.text = [(NSNumber *)tweet[@"favorite_count"] stringValue];
			textCell.retweetedLabel.text = [tweet[@"retweeted"] isEqual: @(YES)] ? @"R" : @"NR";
			textCell.retweetCountLabel.text = [(NSNumber *)tweet[@"retweet_count"] stringValue];
			
			UIImage * userAvatarImage = [self.imageCache objectForKey: userID];
			if(userAvatarImage == nil) {
				[self.timeline getProfilePictureForUserID: tweet[@"user"][@"id"]];
			} else {
				textCell.userAvatarImageView.image = [self.imageCache objectForKey:userID];
			}
		}
		
		
		
        if (indexPath.row % 2 == 1) {
            cell.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1.0];
        } else {
            cell.backgroundColor = [UIColor colorWithWhite:1.0 alpha:1.0];
        }
        
        return cell;
    } else if (indexPath.section == LoadMoreSection) {
        UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:loadMoreReuse forIndexPath:indexPath];
        
        [self loadMoreTweets];
        
        return cell;
    }
    
    return nil;
}

#pragma mark - UserTimelineDelegate

- (void)timeline:(UserTimeline *)timeline didLoginWithError:(NSError *)error {
    if (!error) {
        [timeline getInitalTimeline];
	} else {
		NSLog(@"TimelineTableViewController attempted to login user but there was an error: %@", error.localizedDescription);
	}
}

- (void)timeline:(UserTimeline *)timeline didGetInitalTimeline:(NSArray *)tweets {
    [self.tableView reloadData];
}

- (void)timeline:(UserTimeline *)timeline didGetMoreTimeline:(NSArray *)newTweets {
    [self.tableView reloadData];
}

- (void)timeline:(UserTimeline *)timeline didRefreshTimeline:(NSArray *)newTweets {
    [self.refreshControl endRefreshing];
    
    if (newTweets.count != 0) {
        [self.tableView reloadData];
    }
}

- (void)timeline:(UserTimeline *)timeline didFinishDownloadingProfileImageData:(NSData *)imageData forUserID:(NSNumber *)userID {
    UIImage * image = [UIImage imageWithData:imageData];
    
    [self.imageCache setObject:image forKey:userID];
    
    dispatch_async(dispatch_get_main_queue(), ^{ // Make sure it happens on the main thread
        [self.tableView reloadData];
    });
}

#pragma mark - IBActions

- (IBAction)refresh: (UIRefreshControl *)sender {
    [self.timeline refreshTimeline];
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
