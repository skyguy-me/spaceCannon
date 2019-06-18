//
//  GCHelper.h
//  Gravity-Shooter
//
//  Created by Gokul on 12/1/14.
//  Copyright (c) 2014 Sky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>
#import "Constants.h"

@interface GCHelper : NSObject<GKGameCenterControllerDelegate, GKChallengeListener>{
    
    
    BOOL gameCenterAvailable;
    
    BOOL userAuthenticated;
    
}

@property (assign, readonly) BOOL gameCenterAvailable;

@property (nonatomic, strong) NSArray* leaderboards;
@property (nonatomic, strong) NSMutableDictionary *achievementsDictionary;

+ (GCHelper*)defaultHelper;
- (void)authenticateLocalUserOnViewController:(UIViewController*)viewController
                            setCallbackObject:(id)obj
                            withPauseSelector:(SEL)selector;

- (void)reportScore:(int64_t)score forLeaderboardID:(NSString*)identifier;
- (void)showLeaderboardOnViewController:(UIViewController*)viewController;


@end