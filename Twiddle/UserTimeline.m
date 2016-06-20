//
//  UserTimeline.m
//  Twiddle
//
//  Created by Thomas Ring on 6/20/16.
//  Copyright © 2016 TRing. All rights reserved.
//

#import "UserTimeline.h"

#import <TwitterKit/TwitterKit.h>

@interface UserTimeline()

@property (nonatomic, retain) NSMutableArray * mutableTweets;

@end

@implementation UserTimeline

- (id)init {
    self = [super init];
    
    self.mutableTweets = [[NSMutableArray alloc] init];
    _loggedIn = NO;
    
    return self;
}

- (void)login {
    NSString * userID = [Twitter sharedInstance].sessionStore.session.userID;
    
    [[Twitter sharedInstance] logInWithCompletion:^(TWTRSession *session, NSError *error) {
        if (session) {
            NSLog(@"signed in as %@", [session userName]);
            _loggedIn = YES;
            [self.delegate timeline:self didLoginWithError:nil];
        } else {
            NSLog(@"error: %@", [error localizedDescription]);
            _loggedIn = NO;
            [self.delegate timeline:self didLoginWithError:error];
        }
    }];
}

- (void)getTimeline {
    NSString * userID = [Twitter sharedInstance].sessionStore.session.userID;
    TWTRAPIClient * client = [[TWTRAPIClient alloc] initWithUserID: userID];
    
    NSString *statusesShowEndpoint = @"https://api.twitter.com/1.1/statuses/home_timeline.json";
    NSDictionary *params = @{};
    NSError *clientError;
    
    NSURLRequest *request = [client URLRequestWithMethod:@"GET" URL:statusesShowEndpoint parameters:params error:&clientError];
    
    if (request) {
        [client sendTwitterRequest:request completion:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            if (data) {
                // handle the response data e.g.
                NSError *jsonError;
                NSArray *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                
                [self.mutableTweets addObjectsFromArray:json];
                
                if (self.delegate) {
                    [self.delegate timeline:self didFinishGettingTweets:self.tweets];
                }
            }
            else {
                NSLog(@"Error: %@", connectionError);
            }
        }];
    }
    else {
        NSLog(@"Error: %@", clientError);
    }

}

- (NSArray *)tweets {
    return [self.mutableTweets copy];
}

@end
