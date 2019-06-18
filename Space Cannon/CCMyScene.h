//
//  CCMyScene.h
//  Space Cannon


#import <SpriteKit/SpriteKit.h>
#import "GCHelper.h"

@interface CCMyScene : SKScene <SKPhysicsContactDelegate>

@property (nonatomic) int ammo;
@property (nonatomic) int score;
@property (nonatomic) int pointValue;
@property (nonatomic) BOOL gamePaused;
@property (nonatomic) BOOL _gameOver;
@property (nonatomic) float previous_angle;


@property CGPoint startPoint;

@end
