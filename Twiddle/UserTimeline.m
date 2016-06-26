//
//  UserTimeline.m
//  Twiddle
//
//  Created by Thomas Ring on 6/20/16.
//  Copyright © 2016 TRing. All rights reserved.
//

#import "UserTimeline.h"

#import <TwitterKit/TwitterKit.h>

@interface UserTimeline() <NSURLSessionDelegate, NSURLSessionDownloadDelegate>

@property (nonatomic) NSNumber * minID;

@property (nonatomic) NSNumber * maxID;

@property (nonatomic, retain) NSMutableDictionary<NSNumber *, NSDictionary *> * mutableUserCache;

@property (nonatomic, retain) NSMutableArray * mutableTweets;

@property (nonatomic, retain) NSMutableDictionary<NSNumber *, NSData *> * mutableImageData;

@property (nonatomic, retain) NSURLSession * session;

@property (nonatomic, retain) NSMutableDictionary<NSNumber *, NSNumber *> * userIDForTask;

@end

@implementation UserTimeline

- (id)init {
    self = [super init];
    
    self.maxID = @0;
    self.minID = @0;
    
    self.mutableTweets = [[NSMutableArray alloc] init];
    self.mutableImageData = [[NSMutableDictionary alloc] init];
    self.mutableUserCache = [[NSMutableDictionary alloc] init];
    self.userIDForTask = [[NSMutableDictionary alloc] init];
    _loggedIn = NO;
    
    NSURLSessionConfiguration * configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    
    return self;
}

- (void)login {
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

- (void)sendGetRequestToTwitterURL: (NSString *)url withParams: (NSDictionary *)params withHandler: (void (^)(NSData * data))handler {
    NSString * userID = [Twitter sharedInstance].sessionStore.session.userID;
    TWTRAPIClient * client = [[TWTRAPIClient alloc] initWithUserID: userID];
    
    NSError *clientError;
    
    // Params is allowed to be null so we must make sure that it is not null when we create the request
    if (params == nil) {
        params = [NSDictionary dictionary];
    }
    
    NSURLRequest *request = [client URLRequestWithMethod:@"GET" URL:url parameters:params error:&clientError];
    
    if (request) {
        [client sendTwitterRequest:request completion:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            if (data) {
                handler(data);
            }
            else {
                NSLog(@"Get request to twitte at endpoint %@ failed due to error: %@", url, connectionError.localizedDescription);
            }
        }];
    }
    else if (clientError) {
        NSLog(@"Client error creating NSURLRequest: %@", clientError.localizedDescription);
    } else {
        NSLog(@"Something went very, very wrong.");
    }
}

- (void)getInitalTimeline {
    [self getTimelineWithCount:-1 withMaxID:-1 sinceID:-1 withCompletion:^(NSArray *newData) {
        if (self.delegate) {
            [self.delegate timeline:self didGetInitalTimeline:self.tweets];
        }
    }];
}

- (void)getMoreTimeline {
    NSInteger maxID = [self.minID integerValue] - 1;
    [self getTimelineWithCount:20 withMaxID:maxID sinceID:-1 withCompletion:^(NSArray *newData) {
        if (self.delegate) {
            [self.delegate timeline:self didUpdateTimeline:newData];
        }
    }];
}

// int 64 - count: the number of tweets, must be <= 200
// int 64 - max_id: The maximum ID for the tweet to be loaded INCLUSIVE (use max_id - 1)
// int 64 - since_id: The minimum ID for the tweets to be loaded EXCLUSIVE
- (void)getTimelineWithCount: (NSInteger)count withMaxID: (NSInteger)maxID sinceID: (NSInteger)sinceID withCompletion:(void(^)(NSArray * newData)) completion {
    // Validate all parameters - because we take -1 as no specifier we must be careful what we add to the parameters
    NSMutableDictionary * params = [NSMutableDictionary dictionary];
    
    if (count <= 0) {
        count = 20;
        
    }
    [params setObject:[NSString stringWithFormat:@"%lu", count] forKey:@"count"];
    
    if (maxID > 0) {
        [params setObject:[NSString stringWithFormat:@"%lu", maxID] forKey:@"max_id"];
    }
    
    if (sinceID > 0) {
        [params setObject:[NSString stringWithFormat:@"%lu", sinceID] forKey:@"since_id"];
    }
    
    NSString * url = @"https://api.twitter.com/1.1/statuses/home_timeline.json";
    
    [self sendGetRequestToTwitterURL:url withParams:params withHandler:^(NSData *data) {
        NSError *jsonError;
        NSArray *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        
        for (NSDictionary * tweet in json) {
            // Cache the user data so we don't have to waste a request on it
            NSDictionary * user = tweet[@"user"];
            NSNumber * userID = user[@"id"];
            [self.mutableUserCache setObject:user forKey:userID];
            
            // See if we have the lowest or highest tweet
            NSNumber * tweetID = tweet[@"id"];
            if (self.mutableTweets.count != 0) {
                if ([tweetID compare:self.maxID] == NSOrderedDescending) {
                    self.maxID = tweetID;
                }
                if ([tweetID compare:self.minID] == NSOrderedAscending) {
                    self.minID = tweetID;
                }
            } else {
                self.maxID = tweetID;
                self.minID = tweetID;
            }
            
            
            [self.mutableTweets addObject:tweet];
        }

        if (completion != nil) {
            completion(json);
        }
    }];
}

- (void)getProfilePictureForUserID:(NSNumber *)userID {
    NSData * imageData = [self.mutableImageData objectForKey:userID];
    if (imageData != nil) {
        // We have the data already, return it through the delegate
        NSLog(@"Requested cached profile image, returning without session request.");
        [self.delegate timeline:self didFinishDownloadingProfileImageData:[imageData copy] forUserID:userID];
        return;
    }
    
    // Check if we have the user data cached already
    NSDictionary * user = [self.mutableUserCache objectForKey:userID];
    if (user != nil) {
        if ([self.mutableImageData objectForKey: user[@"id"]] == 0) {
            // We have the user but not the image; download the image now
            [self downloadProfileImageForUserID:userID withProfileImageURL: user[@"profile_image_url_https"]];
            return;
        }
    }
    
    // Get the user we're looking for
    NSLog(@"Downloading user data with ID %@ and then their profile image", userID);
    
    NSString * url = @"https://api.twitter.com/1.1/users/show.json";
    NSDictionary *params = @{@"user_id" : [NSString stringWithFormat:@"%@", userID]};
    
    [self sendGetRequestToTwitterURL: url withParams: params withHandler:^(NSData *data) {
        NSLog(@"User data request returned successfully!");
        
        NSError *jsonError;
        
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        
        // Add the user to cache
        NSNumber * returnedUserID = json[@"id"];
        if ([self.mutableUserCache objectForKey:returnedUserID] != nil) {
            [self.mutableUserCache setObject:json forKey:returnedUserID];
        }
        
        [self downloadProfileImageForUserID:userID withProfileImageURL: @""];
    }];
}

- (void)downloadProfileImageForUserID: (NSNumber *)userID withProfileImageURL: (NSString *)profileImageURL {
    // Make sure the item is not queued already
    if (![self.userIDForTask.allValues containsObject:userID]) {
        NSLog(@"Downloading profile image for cached user with ID: %@", userID);
        
        NSURLSessionDownloadTask * task = [self.session downloadTaskWithURL:[NSURL URLWithString:profileImageURL]];
        [self.userIDForTask setObject:userID forKey:[NSNumber numberWithUnsignedInteger: task.taskIdentifier]];
        [task resume];
    } else {
        
    }
}

- (NSArray *)tweets {
    return [self.mutableTweets copy];
}

#pragma mark - NSURLSessionDelegate

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSData * data = [NSData dataWithContentsOfURL:location];
    
    NSNumber * taskIdentifier = [NSNumber numberWithUnsignedInteger:downloadTask.taskIdentifier];
    NSNumber * userID = [self.userIDForTask objectForKey:taskIdentifier];
    [self.userIDForTask removeObjectForKey:taskIdentifier];
    
    [self.delegate timeline:self didFinishDownloadingProfileImageData:data forUserID:userID];
}

@end
