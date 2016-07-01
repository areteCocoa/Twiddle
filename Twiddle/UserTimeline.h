//
//  UserTimeline.h
//  Twiddle
//
//  Created by Thomas Ring on 6/20/16.
//  Copyright © 2016 TRing. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^UserTimelineLoginCompletion)(NSError * error);

typedef void(^UserTimelineTweetDownloadCompletion)(NSArray * newData, NSArray * oldData, NSError * error);

typedef void(^UserTimelineImageDownloadCompletion)(NSData * imageData, NSError * error);

/**
 *  UserTimeline class is responsible for managing an instance of the user's timeline
 *  as well as getting tweets from the timeline and getting more tweets from the
 *  timeline either by refreshing or getting more. It can also download images but
 *  they are stored as NSData.
 */
@interface UserTimeline : NSObject

/**
 *  An array of all the currently downloaded tweets
 */
@property (nonatomic, readonly) NSArray * tweets;

/**
 *  Whether the user is logged in or not - YES if they are, NO otherwise.
 */
@property (nonatomic, readonly) BOOL loggedIn;

+ (id)sharedTimeline;

/**
 *	Attempts to log in the user via the built in Twitter account support.
 *	Alerts the delegate via timeline: didLoginWithError of the status of
 *	the login attempt after it is completed.
 */
- (void)loginWithCompletion: (UserTimelineLoginCompletion)completion;

/**
 *	Gets the timeline with a no parameter request. Should return the top of
 *	the home timeline. 
 *
 *	Calls the delegate with didGetInitialTimeline after
 *	it is complete.
 */
- (void)getInitalTimelineWithCompletion: (UserTimelineTweetDownloadCompletion)completion;

/**
 *	Gets more of the timeline from the bottom. This should be called when you
 *	want more tweets as if the user is scrolling down through them.
 *
 *	Calls the delegate via didGetMoreTimeline
 */
- (void)getMoreTimelineWithCompletion: (UserTimelineTweetDownloadCompletion)completion;

/**
 *	Refreshes the timeline from the top and attempts to fill in any tweets
 *	that were not loaded in the inital request.
 *
 *	Calls the delegate via didRefreshTimeline
 */
- (void)refreshTimelineWithCompletion: (UserTimelineTweetDownloadCompletion)completion;

/**
 *  Gets a profile picture for the given userID. Returns any data to the delegate
 *	with didFinishDownloadingProfileImageData.
 *
 *  @param userID the ID of the user to be queried
 */
- (void)getProfilePictureForUserID: (NSNumber *)userID withCompletion: (UserTimelineImageDownloadCompletion)completion;

- (void)getImageForImageID:(NSNumber *)imageID withCompletion: (UserTimelineImageDownloadCompletion)completion;

- (void)getImageWithURL: (NSString *)url withCompletion: (UserTimelineImageDownloadCompletion)completion;

@end
