//
//  CCBall.h
//  Space Cannon


#import <SpriteKit/SpriteKit.h>

@interface CCBall : SKSpriteNode

@property (nonatomic) SKEmitterNode *trail;
@property (nonatomic) int bounces;

-(void)updateTrail;

@end
