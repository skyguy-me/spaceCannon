//
//  CCViewController.m
//  Space Cannon


#import "CCViewController.h"
#import "CCMyScene.h"
#import "CCMenu.h"
#import "CCMyScene.h"
#import <iAd/iAd.h>



@implementation CCViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Configure the view.
    SKView * skView = (SKView *)self.view;
    skView.showsFPS = NO;
    skView.showsNodeCount = NO;
    
    
    // Make self the delegate of the ad banner.
    self.adBanner.delegate = self;
    
    
    // Initially hide the ad banner.
    self.adBanner.alpha = 0.0;
    // Create and configure the scene.
    SKScene * scene = [CCMyScene sceneWithSize:skView.bounds.size];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    scene.backgroundColor = [UIColor blackColor];
    // Present the scene.
    [skView presentScene:scene];
    
}

-(void)bannerViewWillLoadAd:(ADBannerView *)banner{
    NSLog(@"Ad Banner will load ad.");
    
    
    // Show
    [UIView animateWithDuration:0.5 animations:^{
        self.adBanner.alpha = 0.0;//change
    }];
}


-(BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave{
    NSLog(@"Ad Banner action is about to begin.");
    self.adBanner.alpha = 1.0;

    return YES;
}



-(void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error{
    NSLog(@"Unable to show ads. Error: %@", [error localizedDescription]);
    
    // Hide the ad banner.
    [UIView animateWithDuration:0.5 animations:^{
        self.adBanner.alpha = 0.0;
    }];}

- (BOOL)shouldAutorotate
{
    return NO;
}



- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

@end
