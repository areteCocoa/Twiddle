//
//  UserTimeline.m
//  Twiddle
//
//  Created by Thomas Ring on 6/20/16.
//  Copyright © 2016 TRing. All rights reserved.
//

#import "UserTimeline.h"

#import <TwitterKit/TwitterKit.h>

/**
 *  A handler for when any tweets are returned from a request to twitter.
 *
 *	It does not return ALL data because it is already stored by the time it is being
 *	passed as newData.
 *
 *  @param newData The new data returned from the request
 *  @param minID   The smallest tweet id of the request
 *  @param maxID   The largest tweet id of the request
 */
typedef void(^TweetHandlerCompletion)(NSArray * newData, NSNumber * minID, NSNumber * maxID);



@interface UserTimeline() <NSURLSessionDelegate, NSURLSessionDownloadDelegate>

/**
 *  The smallest tweet ID this timeline currently has
 */
@property (nonatomic) NSNumber * minID;

/**
 *  The largest tweet ID this timeline currently has
 */
@property (nonatomic) NSNumber * maxID;

/**
 *  The internal array of tweets in this timeline
 */
@property (nonatomic, retain) NSMutableArray * mutableTweets;

/**
 *  A cache of user data given their user ID
 *
 *	<key> -> The user ID
 *	<value> -> The JSON user data
 */
@property (nonatomic, retain) NSMutableDictionary<NSNumber *, NSDictionary *> * mutableUserCache;

/**
 *  A cache of photo entity metadata
 *
 *	<key> -> The photo ID
 *	<value> -> The photo metadata
 */
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSDictionary *> * mutableImageEntityCache;

/**
 *  A cache of the NSData for the images that have been downloaded
 */
@property (nonatomic, strong) NSMutableDictionary<id, NSData *> * mutableImageData;

/**
 *  A cache of user image data given their user ID
 *
 *	<key> -> The user ID
 *	<value> -> The JSON image data for that user
 */
@property (nonatomic, retain) NSMutableDictionary<NSNumber *, NSData *> * mutableUserProfileImageData;

/**
 *  An NSURLSession used for downloading images and other things not downloaded via
 *	the Twitter API
 */
@property (nonatomic, retain) NSURLSession * session;

/**
 *  A dictionary tracking the user ID for download tasks for when downloading profile image data
 *
 *	<key> -> The task identifier
 *	<value> -> The user ID
 */
@property (nonatomic, retain) NSMutableDictionary<NSNumber *, NSNumber *> * userIDForTask;

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSNumber *> * imageIDForTask;

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSString *> * imageURLForTask;

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, id> * completionForTask;

/**
 *  Sends a request to a Twitter URL with params as parameters and calls handler with the data when
 *  it is done
 *
 *  @param url     The URL to be called
 *  @param params  Parameters for the API call
 *  @param handler A handler for if the data is valid
 */
- (void)sendGetRequestToTwitterURL: (NSString *)url withParams: (NSDictionary *)params withHandler: (void (^)(NSData * data))handler;

/**
 *  Fetches the user timeline for count number of tweets with maxID and sinceID as parameters. Calls completion
 *	when it is done processing the data
 *
 *  @param count      The number of tweets to be fetched
 *  @param maxID      The maximum tweet ID allowed; inclusive
 *  @param sinceID    The minimum tweet ID allowed; exclusive
 *  @param completion The completion handler for when the fetch is complete and the data is handled
 */
- (void)getTimelineWithCount: (NSInteger)count withMaxID: (NSInteger)maxID sinceID: (NSInteger)sinceID withCompletion:(TweetHandlerCompletion) completion;

/**
 *  Download the user with userID's profile image data and returns it to the handler
 *
 *  @param userID          the user's userID
 *  @param profileImageURL the URL of the profile image
 */
- (void)downloadProfileImageForUserID: (NSNumber *)userID withProfileImageURL: (NSString *)profileImageURL;

@end

@implementation UserTimeline

+ (id)sharedTimeline {
	static UserTimeline * sharedTimeline = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedTimeline = [[self alloc] init];
	});
	return sharedTimeline;
}

- (id)init {
    self = [super init];
    
    self.maxID = @0;
    self.minID = @0;
    
    self.mutableTweets = [[NSMutableArray alloc] init];
	self.mutableUserCache = [[NSMutableDictionary alloc] init];
	self.mutableImageEntityCache = [NSMutableDictionary dictionary];
	self.mutableImageData = [NSMutableDictionary dictionary];
    self.mutableUserProfileImageData = [[NSMutableDictionary alloc] init];
	
    self.userIDForTask = [[NSMutableDictionary alloc] init];
	self.imageIDForTask = [NSMutableDictionary dictionary];
	self.imageURLForTask = [NSMutableDictionary dictionary];
	self.completionForTask = [NSMutableDictionary dictionary];
    _loggedIn = NO;
    
    NSURLSessionConfiguration * configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    
    return self;
}

- (void)login {
    [[Twitter sharedInstance] logInWithCompletion:^(TWTRSession *session, NSError *error) {
        if (session) {
            NSLog(@"Successfully signed in as %@.", [session userName]);
            _loggedIn = YES;
            [self.delegate timeline:self didLoginWithError:nil];
        } else {
            NSLog(@"Attempted to log in but there was an error: %@", [error localizedDescription]);
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
                NSLog(@"GET request to Twitter at endpoint %@ failed due to error: %@", url, connectionError.localizedDescription);
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
    [self getTimelineWithCount:-1 withMaxID:-1 sinceID:-1 withCompletion:^(NSArray *newData, NSNumber *minID, NSNumber *maxID) {
        if (self.delegate) {
            [self.delegate timeline:self didGetInitalTimeline:self.tweets];
        }
    }];
}

- (void)getMoreTimeline {
    NSInteger maxID = [self.minID integerValue] - 1;
    [self getTimelineWithCount:20 withMaxID:maxID sinceID:-1 withCompletion:^(NSArray *newData, NSNumber* minID, NSNumber * maxID) {
        if (self.delegate) {
            [self.delegate timeline:self didGetMoreTimeline:newData];
        }
    }];
}

- (void)refreshTimeline {
    NSInteger sinceID = [self.maxID integerValue];
    [self getTimelineWithCount:20 withMaxID:-1 sinceID:sinceID withCompletion:^(NSArray *newData, NSNumber * minID, NSNumber * maxID) {
        if (newData.count == 0) {
            NSLog(@"ALL UPDATED!");
        } else {
            NSLog(@"We have more data.");
        }
        if (self.delegate) {
            [self.delegate timeline:self didRefreshTimeline:newData];
        }
    }];
}

// int 64 - count: the number of tweets, must be <= 200
// int 64 - max_id: The maximum ID for the tweet to be loaded INCLUSIVE (use max_id - 1)
// int 64 - since_id: The minimum ID for the tweets to be loaded EXCLUSIVE
- (void)getTimelineWithCount: (NSInteger)count withMaxID: (NSInteger)maxID sinceID: (NSInteger)sinceID withCompletion:(TweetHandlerCompletion) completion {
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
		
		if (jsonError != nil) {
			NSLog(@"There was an error parsing returned JSON data from Twitter: %@", jsonError.localizedDescription);
		}
        
        NSNumber * requestMaxID = @0, * requestMinID = @0;
        
        for (NSDictionary * tweet in json) {
            // Cache the user data so we don't have to waste a request on it
            NSDictionary * user = tweet[@"user"];
            NSNumber * userID = user[@"id"];
            [self.mutableUserCache setObject:user forKey:userID];
            
            // See if we have the lowest or highest tweet in this request
            NSNumber * tweetID = tweet[@"id"];
            if ([tweetID compare: requestMaxID] == NSOrderedDescending || [requestMaxID isEqualToNumber:@0]) {
                requestMaxID = tweetID;
            }
            if ([tweetID compare: requestMinID] == NSOrderedAscending || [requestMinID isEqualToNumber:@0]) {
                requestMinID = tweetID;
            }
			
			// Add any entity metadata to caches
			for (NSDictionary * entity in tweet[@"entities"][@"media"]) {
				NSString * type = entity[@"type"];
				if ([type isEqualToString:@"photo"]) {
					NSNumber * imageID = entity[@"id"];
					[self.mutableImageEntityCache setObject: entity forKey: imageID];
				} else {
					NSLog(@"There is a media entity I don't know how to handle of type: %@", type);
				}
			}
            
            [self.mutableTweets addObject:tweet];
        }
        
        // Set this timeline's max and min
        if (self.mutableTweets.count != 0) {
            if ([requestMaxID compare:self.maxID] == NSOrderedDescending) {
                self.maxID = requestMaxID;
            }
            if ([requestMinID compare:self.minID] == NSOrderedAscending) {
                self.minID = requestMinID;
            }
        } else {
            self.maxID = requestMaxID;
            self.minID = requestMinID;
        }
        

        if (completion != nil) {
            completion(json, requestMaxID, requestMinID);
        }
    }];
}

- (void)getProfilePictureForUserID:(NSNumber *)userID {
    NSData * imageData = [self.mutableUserProfileImageData objectForKey:userID];
    if (imageData != nil) {
        // We have the data already, return it through the delegate
        NSLog(@"Requested cached profile image, returning without session request.");
        [self.delegate timeline:self didFinishDownloadingProfileImageData:[imageData copy] forUserID:userID];
        return;
    }
    
    // Check if we have the user data cached already
    NSDictionary * user = [self.mutableUserCache objectForKey:userID];
    if (user != nil) {
        if ([self.mutableUserProfileImageData objectForKey: user[@"id"]] == 0) {
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
		
		if (jsonError != nil) {
			NSLog(@"There was an error in parsing returned JSON data: %@", jsonError.localizedDescription);
		}
        
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

- (void)getImageForImageID:(NSNumber *)imageID {
	NSData * imageData = [self.mutableImageData objectForKey:imageID];
	if (imageData != nil) {
		[self.delegate timeline:self didFinishDownloadingImage:imageData forImageID:imageID];
		return;
	}
	
	NSDictionary * imageMetadata = self.mutableImageEntityCache[imageID];
	if (imageMetadata != nil) {
		// We have the URL cached, we can just download it
		NSString * url = imageMetadata[@"media_url_https"];
		[self downloadImageForImageID:imageID withImageURL:url];
		return;
	}
	
	// In the rare occasion that the client wants to download an image that we have not cached
	// the metadata for yet, we can manually download the image data and then download the
	// image.
	
	// This code will break the world
	NSLog(@"YOU BROKE ME");
	id d = [NSMutableDictionary dictionary];
	id a = [NSArray array];
	[d isEqual:a];
}

- (void)getImageForImageID:(NSNumber *)imageID withCompletion:(UserTimelineImageDownloadCompletion)completion {
	NSData * imageData = [self.mutableImageData objectForKey:imageID];
	if (imageData != nil) {
		if (completion) {
			completion(imageData, nil);
		} else {
			[self.delegate timeline:self didFinishDownloadingImage:imageData forImageID:imageID];
		}
		return;
	}
	
	NSDictionary * imageMetadata = self.mutableImageEntityCache[imageID];
	if (imageMetadata != nil) {
		// We have the URL cached, we can just download it
		NSString * url = imageMetadata[@"media_url_https"];
		[self downloadImageForImageID:imageID withImageURL:url];
		return;
	}
	
	NSLog(@"Attempted to download an image with ID for which we have no metadata!");
}

- (void)downloadImageForImageID: (NSNumber *)imageID withImageURL: (NSString *)url {
	[self downloadImageForImageID:imageID withImageURL:url withCompletion:nil];
}

- (void)downloadImageForImageID: (NSNumber *)imageID withImageURL:(NSString *)url withCompletion: (UserTimelineImageDownloadCompletion)completion {
	// Make sure the item is not queued already
	if (![self.imageIDForTask.allValues containsObject:imageID]) {
		NSLog(@"Downloading image with ID: %@", imageID);
		
		NSURLSessionDownloadTask * task = [self.session downloadTaskWithURL:[NSURL URLWithString: url]];
		[self.imageIDForTask setObject:imageID forKey:[NSNumber numberWithInteger: task.taskIdentifier]];
		
		if (completion != nil) {
			[self.completionForTask setObject:completion forKey:[NSNumber numberWithInteger: task.taskIdentifier]];
		}
		
		[task resume];
	} else {
		NSLog(@"Something else tried to download an image that is already queued to download.");
	}
}

- (void)getImageWithURL: (NSString *)url withCompletion: (UserTimelineImageDownloadCompletion)completion {
	if (!url) {
		NSLog(@"Attempted to download an image but no url was passed!");
		return;
	}
	
	NSData * imageData = self.mutableImageData[url];
	if (imageData) {
		completion(imageData, nil);
	}
	
	// Make sure the item is not queued already
	if (![self.imageURLForTask.allValues containsObject: url]) {
		NSLog(@"Downloading image with URL: %@", url);
		
		NSURLSessionDownloadTask * task = [self.session downloadTaskWithURL:[NSURL URLWithString: url]];
		[self.imageURLForTask setObject:url forKey:[NSNumber numberWithInteger: task.taskIdentifier]];
		
		if (completion != nil) {
			[self.completionForTask setObject:completion forKey:[NSNumber numberWithInteger: task.taskIdentifier]];
		}
		
		[task resume];
	} else {
		NSLog(@"Something else tried to download an image that is already queued to download.");
	}
}

- (NSArray *)tweets {
	if (!self.mutableTweets) {
		NSLog(@"TRIED TO GET TWEETS BEFORE IT WAS EVEN INSTANTIATED!");
	}
	
    return [self.mutableTweets copy];
}

#pragma mark - NSURLSessionDelegate

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
	NSData * data = [NSData dataWithContentsOfURL:location];
	NSNumber * taskIdentifier = [NSNumber numberWithInteger:downloadTask.taskIdentifier];
	
	if ([self.imageIDForTask.allKeys containsObject: taskIdentifier]) {
		// It's an image
		NSNumber * imageID = [self.imageIDForTask objectForKey:taskIdentifier];
		[self.imageIDForTask removeObjectForKey:taskIdentifier];
		
		UserTimelineImageDownloadCompletion completion = [self.completionForTask objectForKey:taskIdentifier];
		if (completion) {
			completion(data, nil);
			[self.completionForTask removeObjectForKey:taskIdentifier];
		} else {
			[self.delegate timeline:self didFinishDownloadingImage:data forImageID: imageID];
		}
	} else if ([self.userIDForTask.allKeys containsObject:taskIdentifier]) {
		// It's a profile image
		NSNumber * userID = [self.userIDForTask objectForKey:taskIdentifier];
		[self.userIDForTask removeObjectForKey:taskIdentifier];
		
		[self.delegate timeline:self didFinishDownloadingProfileImageData:data forUserID:userID];
	} else if ([self.imageURLForTask.allKeys containsObject:taskIdentifier]) {
		// It's an image
		[self.imageURLForTask removeObjectForKey:taskIdentifier];
		
		UserTimelineImageDownloadCompletion completion = [self.completionForTask objectForKey:taskIdentifier];
		if (completion) {
			completion(data, nil);
		}
	}
	else {
		NSLog(@"UserTimeline downloaded data and doesn't know what to do with it!");
	}
}

@end
