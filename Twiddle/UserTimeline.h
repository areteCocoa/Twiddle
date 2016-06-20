//
//  UserTimeline.h
//  Twiddle
//
//  Created by Thomas Ring on 6/20/16.
//  Copyright © 2016 TRing. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol UserTimelineDelegate;

@interface UserTimeline : NSObject

@property (nonatomic, retain) NSObject<UserTimelineDelegate> * delegate;

@property (nonatomic, readonly) NSArray * tweets;

@property (nonatomic, readonly) BOOL loggedIn;

- (void)login;
- (void)getTimeline;

@end



@protocol UserTimelineDelegate <NSObject>

- (void)timeline:(UserTimeline *) timeline didLoginWithError: (NSError *)error;

- (void)timeline:(UserTimeline *) timeline didFinishGettingTweets: (NSArray *)tweets;

@end