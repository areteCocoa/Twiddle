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

@property (nonatomic, retain) NSMutableDictionary<NSNumber *, NSDictionary *> * mutableUserCache;

@property (nonatomic, retain) NSMutableArray * mutableTweets;

@property (nonatomic, retain) NSMutableDictionary<NSNumber *, NSData *> * mutableImageData;

@property (nonatomic, retain) NSURLSession * session;

@property (nonatomic, retain) NSMutableDictionary<NSNumber *, NSNumber *> * userIDForTask;

@end

@implementation UserTimeline

- (id)init {
    self = [super init];
    
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

- (void)getProfilePictureForUserID:(NSNumber *)userID {
    NSData * imageData = [self.mutableImageData objectForKey:userID];
    if (imageData != nil) {
        // We have the data already, return it through the delegate
        NSLog(@"Requested cached profile picture, returning without session request.");
        [self.delegate timeline:self didFinishDownloadingProfileImageData:[imageData copy] forUserID:userID];
        return;
    }
    
    // Check if we have the user data cached already
    NSDictionary * user = [self.mutableUserCache objectForKey:userID];
    if (user != nil) {
        // We have the user but not the image; download the image now
        [self downloadProfileImageForUserID:userID withProfileImageURL: user[@"profile_image_url_https"]];
        return;
    }
    
    // Get the user we're looking for
    NSLog(@"Downloading user data with ID %@ and then their profile image", userID);
    
    NSString * uID = [Twitter sharedInstance].sessionStore.session.userID;
    TWTRAPIClient * client = [[TWTRAPIClient alloc] initWithUserID: uID];
    
    NSString *statusesShowEndpoint = @"https://api.twitter.com/1.1/users/show.json";
    NSDictionary *params = @{@"user_id" : [NSString stringWithFormat:@"%@", userID]};
    NSError *clientError;
    
    NSURLRequest *request = [client URLRequestWithMethod:@"GET" URL:statusesShowEndpoint parameters:params error:&clientError];
    if (request) {
        [client sendTwitterRequest:request completion:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
            if (data) {
                NSLog(@"User data request returned successfully!");
                
                NSError *jsonError;
                
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                
                // Add the user to cache
                NSNumber * returnedUserID = json[@"id"];
                if ([self.mutableUserCache objectForKey:returnedUserID] != nil) {
                    [self.mutableUserCache setObject:json forKey:returnedUserID];
                }
                
                [self downloadProfileImageForUserID:userID withProfileImageURL: @""];
            }
            else {
                NSLog(@"Error: %@", connectionError);
            }
        }];
    }
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
                
                for (NSDictionary * tweet in json) {
                    // Cache the user data so we don't have to waste a request on it
                    NSDictionary * user = tweet[@"user"];
                    NSNumber * userID = user[@"id"];
                    [self.mutableUserCache setObject:user forKey:userID];
                    
                    [self.mutableTweets addObject:tweet];
                }
                
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
