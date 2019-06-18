//
//  CCViewController.h
//  Space Cannon
//


#import <UIKit/UIKit.h>
#import <SpriteKit/SpriteKit.h>
#import <iAd/iAd.h>
#import "CCMyScene.h"
#import "CCMenu.h"
#import "CCMyScene.h"

@interface CCViewController : UIViewController <ADBannerViewDelegate>

@property (weak, nonatomic) IBOutlet ADBannerView *adBanner;

@end
