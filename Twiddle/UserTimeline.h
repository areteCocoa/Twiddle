//
//  UserTimeline.h
//  Twiddle
//
//  Created by Thomas Ring on 6/20/16.
//  Copyright © 2016 TRing. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol UserTimelineDelegate;

typedef void(^UserTimelineImageDownloadCompletion)(NSData * imageData, NSError * error);

/**
 *  UserTimeline class is responsible for managing an instance of the user's timeline
 *  as well as getting tweets from the timeline and getting more tweets from the
 *  timeline either by refreshing or getting more. It can also download images but
 *  they are stored as NSData.
 */
@interface UserTimeline : NSObject

/**
 *  The delegate for this instance.
 */
@property (nonatomic, retain) NSObject<UserTimelineDelegate> * delegate;

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
- (void)login;

/**
 *	Gets the timeline with a no parameter request. Should return the top of
 *	the home timeline. 
 *
 *	Calls the delegate with didGetInitialTimeline after
 *	it is complete.
 */
- (void)getInitalTimeline;

/**
 *	Gets more of the timeline from the bottom. This should be called when you
 *	want more tweets as if the user is scrolling down through them.
 *
 *	Calls the delegate via didGetMoreTimeline
 */
- (void)getMoreTimeline;

/**
 *	Refreshes the timeline from the top and attempts to fill in any tweets
 *	that were not loaded in the inital request.
 *
 *	Calls the delegate via didRefreshTimeline
 */
- (void)refreshTimeline;

/**
 *  Gets a profile picture for the given userID. Returns any data to the delegate
 *	with didFinishDownloadingProfileImageData.
 *
 *  @param userID the ID of the user to be queried
 */
- (void)getProfilePictureForUserID: (NSNumber *)userID;

/**
 *  Gets an image given the imageID. Returns any data to the delegate with
 *	didFinishDownloadingImageData
 *
 *  @param imageID the ID of the image to be found
 */
- (void)getImageForImageID: (NSNumber *)imageID;

- (void)getImageForImageID:(NSNumber *)imageID withCompletion: (UserTimelineImageDownloadCompletion)completion;

- (void)getImageWithURL: (NSString *)url withCompletion: (UserTimelineImageDownloadCompletion)completion;

@end


/**
 *  The UserTimelineDelegate protocol defines a class that can receive data about how
 *	a timeline is doing and handle any data is has appropriately.
 */
@protocol UserTimelineDelegate <NSObject>

/**
 *  The UserTimeline finshed its login attempt
 *
 *  @param timeline The timeline that finished its login attempt
 *  @param error    The error that occured when the timeline tried to login
 */
- (void)timeline:(UserTimeline *) timeline didLoginWithError: (NSError *)error;

/**
 *  The UserTimeline finished getting the initial timeline
 *
 *  @param timeline The timeline that finished the login attempt
 *  @param tweets   The array of tweets returned to the timeline
 */
- (void)timeline:(UserTimeline *) timeline didGetInitalTimeline: (NSArray *)tweets;

/**
 *  The UserTimeline finished getting more tweets and returns the new tweets
 *
 *  @param timeline  The timeline that finished
 *  @param newTweets An NSArray of the tweets that were just fetched
 */
- (void)timeline: (UserTimeline *) timeline didGetMoreTimeline: (NSArray*)newTweets;

/**
 *  The UserTimeline finished refreshing tweets and is returning all the new tweets
 *
 *  @param timeline  The timeline that finished refreshing
 *  @param newTweets An NSArray of the tweets that were just fetched
 */
- (void)timeline: (UserTimeline *) timeline didRefreshTimeline: (NSArray *)newTweets;

/**
 *  The UserTimeline finished downloading a profile image
 *
 *  @param timeline  The timeline that finished the downloading
 *  @param imageData The imageData that was downloaded
 *  @param userID    The userID for which the imageData corresponds to
 */
- (void)timeline:(UserTimeline *) timeline didFinishDownloadingProfileImageData: (NSData *)imageData forUserID: (NSNumber *)userID;

- (void)timeline:(UserTimeline *)timeline didFinishDownloadingImage: (NSData *)imageData forImageID: (NSNumber *)imageID;

@end