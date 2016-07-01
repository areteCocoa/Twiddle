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

static CGFloat textCellHeight = 90;
static CGFloat loadMoreCellHeight = 40;

typedef enum : NSUInteger {
    TweetsSection,
    LoadMoreSection,
} TimelineTableViewControllerSection;

@interface TimelineTableViewController () <UserTimelineDelegate>

@property (nonatomic, retain) UserTimeline * timeline;

@property (nonatomic, retain) NSMutableDictionary<NSNumber *, UIImage *> * userProfileImageCache;

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, UIImage *> * imageCache;

@property (nonatomic) CGFloat textViewWidth;

@end

@implementation TimelineTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blueColor];
    
    self.userProfileImageCache = [[NSMutableDictionary alloc] init];
	self.imageCache = [NSMutableDictionary dictionary];
    
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
				NSNumber * imageHeight = imageSizes[@"large"][@"h"], * imageWidth = imageSizes[@"large"][@"w"];
				
				CGFloat imageWidthFloat = [imageWidth floatValue], imageHeightFloat = [imageHeight floatValue];
				
				CGFloat cellWidth = self.tableView.frame.size.width;
				CGFloat cellHeight = (cellWidth * imageHeightFloat) / imageWidthFloat;
				
				return cellHeight;
			} else {
				if (self.textViewWidth == 0) {
					return textCellHeight;
				}
				
				NSString * tweetText = tweet[@"text"];
				NSAttributedString * attributedString = [[NSAttributedString alloc] initWithString:tweetText attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:17.0]}];
				CGFloat textViewHeight = [self textViewHeightForAttributedText:attributedString andWidth: self.textViewWidth];
				
				CGFloat otherHeight = 50;
				CGFloat dynamicHeight = textViewHeight + otherHeight;
				
				return dynamicHeight > textCellHeight ? dynamicHeight : textCellHeight;
			}
		}
		
        return textCellHeight;
    } else if (indexPath.section == LoadMoreSection) {
        return loadMoreCellHeight;
    }
    return 0;
}

- (CGFloat)textViewHeightForAttributedText:(NSAttributedString *)text andWidth:(CGFloat)width
{
	UITextView *textView = [[UITextView alloc] init];
	[textView setAttributedText:text];
	CGSize size = [textView sizeThatFits:CGSizeMake(width, FLT_MAX)];
	return size.height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == TweetsSection) {
		UITableViewCell * cell;
		
		// Fetch the data first
		NSDictionary * tweet = self.timeline.tweets[indexPath.row];
		
		// Figure out what kind of tweet we have -- text or image or link
		if ([[tweet[@"entities"][@"media"] firstObject][@"type"] isEqualToString:@"photo"]) {
			// We need an image cell
			cell = [tableView dequeueReusableCellWithIdentifier:imageCellReuse forIndexPath:indexPath];
			
			// Setup text info
			TweetImageTableViewCell * imageCell = (TweetImageTableViewCell *)cell;
			[self loadTextCell:imageCell withTweet:tweet];
			
			// Get the image metadata
			NSNumber * imageID = [tweet[@"entities"][@"media"] firstObject][@"id"];
			
			// Load image
			UIImage * image = self.imageCache[imageID];
			if (image == nil) {
				[self.timeline getImageForImageID:imageID];
			} else {
				imageCell.contentImageView.image = image;
			}
		} else {
			// We need a text cell
			cell = [tableView dequeueReusableCellWithIdentifier:textCellReuse forIndexPath:indexPath];
			
			// Configure the cell...
			TweetTextTableViewCell * textCell = (TweetTextTableViewCell *)cell;
			
			[self loadTextCell:textCell withTweet:tweet];
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

- (void)loadTextCell: (TweetTextTableViewCell *)cell withTweet: (NSDictionary *)tweet {
	NSNumber * userID = tweet[@"user"][@"id"];
	
	// Setup properties
	cell.handleLabel.text = tweet[@"user"][@"name"];
	cell.screenNameLabel.text = [NSString stringWithFormat:@"@%@", tweet[@"user"][@"screen_name"]];
	
	// Set inset
	cell.tweetTextLabel.text = tweet[@"text"];
	if (self.textViewWidth == 0) {
		self.textViewWidth = cell.tweetTextLabel.frame.size.width;
	}
	
	// How long ago was it posted?
	// Wed Jun 29 6:52:07 +0000 2016
	NSString * timeSinceString = @"";
	NSString * dateString = tweet[@"created_at"];
	NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
	formatter.dateFormat = @"EEE MMM dd HH:mm:ss ZZZ yyyy";
	NSDate * date = [formatter dateFromString: dateString];
	NSTimeInterval interval = 0 - [date timeIntervalSinceNow];
	int seconds = floor(interval);
	int minutes = floor(seconds / 60);
	int hours = floor(minutes / 60);
	int days = floor(hours / 24);
	int weeks = floor(days / 7);
	int months = floor(weeks / 52);
	int years = floor(months / 12);
	if (years > 0) {
		timeSinceString = [NSString stringWithFormat:@"%d years ago", years];
	} else if (months > 0) {
		timeSinceString = [NSString stringWithFormat:@"%d months ago", months];
	} else if (days > 0) {
		timeSinceString = [NSString stringWithFormat:@"%d days ago", days];
	} else if (hours > 0) {
		timeSinceString = [NSString stringWithFormat:@"%d hours ago", hours];
	} else if (minutes > 0) {
		timeSinceString = [NSString stringWithFormat:@"%d minutes ago", minutes];
	} else if (seconds > 0) {
		timeSinceString = [NSString stringWithFormat:@"%d seconds ago", seconds];
	} else {
		timeSinceString = @"now";
	}
	cell.createdDateLabel.text = timeSinceString;
	
	cell.favoritesCountLabel.text = [NSString stringWithFormat:@"%@ favorites", (NSNumber *)tweet[@"favorite_count"]];
	if ([tweet[@"favorited"]  isEqual: @(YES)]) {
		cell.favoritesCountLabel.font = [UIFont boldSystemFontOfSize:12.0];
	} else {
		cell.favoritesCountLabel.font = [UIFont systemFontOfSize:12.0];
	}
	
	cell.retweetCountLabel.text = [NSString stringWithFormat:@"%@ retweets", (NSNumber *)tweet[@"retweet_count"]];
	if ([tweet[@"retweeted"] isEqual: @(YES)]) {
		cell.retweetCountLabel.font = [UIFont boldSystemFontOfSize:12.0];
	} else {
		cell.retweetCountLabel.font = [UIFont systemFontOfSize:12.0];
	}
	
	UIImage * userAvatarImage = [self.userProfileImageCache objectForKey: userID];
	if(userAvatarImage == nil) {
		[self.timeline getProfilePictureForUserID: tweet[@"user"][@"id"]];
	} else {
		UIImageView * imageView = cell.userAvatarImageView;
		
		imageView.image = userAvatarImage;
		imageView.layer.cornerRadius = imageView.frame.size.width / 2;
		imageView.layer.masksToBounds = YES;
	}
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self performSegueWithIdentifier:@"profile_segue" sender:self];
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
	
    [self.userProfileImageCache setObject:image forKey:userID];
    
    dispatch_async(dispatch_get_main_queue(), ^{ // Make sure it happens on the main thread
        [self.tableView reloadData];
    });
}

- (void)timeline:(UserTimeline *)timeline didFinishDownloadingImage:(NSData *)imageData forImageID:(NSNumber *)imageID {
	UIImage * image = [UIImage imageWithData: imageData];
	
	[self.imageCache setObject:image forKey:imageID];
	
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
