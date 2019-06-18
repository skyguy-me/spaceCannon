//
//  CCMenu.h
//  Space Cannon

#import <SpriteKit/SpriteKit.h>

@interface CCMenu : SKNode

@property (nonatomic) int score;
@property (nonatomic) int topScore;
@property (nonatomic) BOOL touchable;
@property (nonatomic) BOOL musicPlaying;
-(void)hide;
-(void)show;

@end
