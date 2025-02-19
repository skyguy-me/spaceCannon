//
//  CCMyScene.m
//  Space Cannon


#import "CCMyScene.h"
#import "CCMenu.h"
#import "CCBall.h"
#import "CCViewController.h"
#import "constants.h"
#import <AVFoundation/AVFoundation.h>

@implementation CCMyScene
{
    AVAudioPlayer *_audioPlayer;
    SKNode *_mainLayer;
    CCMenu *_menu;
    SKSpriteNode *_cannon;
    SKSpriteNode *_ammoDisplay;
    SKSpriteNode *_pauseButton;
    SKSpriteNode *_resumeButton;
    SKSpriteNode *_cannon2;
    
    SKLabelNode *_scoreLabel;
    SKLabelNode *_pointLabel;
    BOOL _didShoot;
    BOOL _isMoving;
    
    SKAction *_bounceSound;
    SKAction *_deepExplosionSound;
    SKAction *_explosionSound;
    SKAction *_laserSound;
    SKAction *_zapSound;
    SKAction *_shieldUpSound;
    
    NSUserDefaults *_userDefaults;
    NSMutableArray *_shieldPool;
    int Music;
}

static const CGFloat kCCShootSpeed = 1000.0;
static const CGFloat kCCHaloLowAngle = 200.0 * M_PI / 180.0;
static const CGFloat kCCHaloHighAngle = 340.0 * M_PI / 180.0;
static const CGFloat kCCHaloSpeed = 100.0;

static const uint32_t kCCHaloCategory      = 0x1 << 0;
static const uint32_t kCCBallCategory      = 0x1 << 1;
static const uint32_t kCCEdgeCategory      = 0x1 << 2;
static const uint32_t kCCShieldCategory    = 0x1 << 3;
static const uint32_t kCCLifeBarCategory   = 0x1 << 4;
static const uint32_t kCCShieldUpCategory  = 0x1 << 5;
//static const uint32_t kCCExplodeBarrell    = 0x1 << 6;

static NSString * const kCCKeyTopScore = @"TopScore";

static inline CGVector radiansToVector(CGFloat radians)
{
    CGVector vector;
    vector.dx = cosf(radians);
    vector.dy = sinf(radians);
    return vector;
}


static inline CGFloat randomInRange(CGFloat low, CGFloat high)
{
    CGFloat value = arc4random_uniform(UINT32_MAX) / (CGFloat)UINT32_MAX;
    return value * (high - low) + low;
}

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        
        // Turn off gravity.
        self.physicsWorld.gravity = CGVectorMake(0.0, 0.0);
        self.physicsWorld.contactDelegate = self;
        
        // Add background.
        SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"Starfield"];
        background.position = CGPointZero;
        background.anchorPoint = CGPointZero;
        background.blendMode = SKBlendModeReplace;
        background.alpha = 0.6;
        [self addChild:background];
        
        // Add edges.
        SKNode *leftEdge = [[SKNode alloc] init];
        leftEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointZero toPoint:CGPointMake(0.0, self.size.height + 100)];
        leftEdge.position = CGPointZero;
        leftEdge.physicsBody.categoryBitMask = kCCEdgeCategory;
        [self addChild:leftEdge];
        
        SKNode *rightEdge = [[SKNode alloc] init];
        rightEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointZero toPoint:CGPointMake(0.0, self.size.height + 100)];
        rightEdge.position = CGPointMake(self.size.width, 0.0);
        rightEdge.physicsBody.categoryBitMask = kCCEdgeCategory;
        [self addChild:rightEdge];
        
        
        // Add main layer.
        _mainLayer = [[SKNode alloc] init];
        [self addChild:_mainLayer];
        
        // Add cannon.
        _cannon = [SKSpriteNode spriteNodeWithImageNamed:@"Cannon"];
        //_cannon2 = [SKSpriteNode spriteNodeWithImageNamed:<#(NSString *)#>];
        _cannon.position = CGPointMake(self.size.width * 0.5, 0.0);
        [self addChild:_cannon];
        
        // Create cannon rotation actions.
        // SKAction *rotateCannon = [SKAction sequence:@[[SKAction rotateByAngle:M_PI duration:2],
        //                                               [SKAction rotateByAngle:-M_PI/2 duration:2]]];
        
        // [_cannon runAction:[SKAction repeatActionForever:rotateCannon]];
        
        
        //updated acti on for version x
        //[_cannon runAction:rotateCannon];
        
        // Create spawn halo actions.
        SKAction *spawnHalo = [SKAction sequence:@[[SKAction waitForDuration:1.55 withRange:1],
                                                   [SKAction performSelector:@selector(spawnHalo) onTarget:self]]];
        [self runAction:[SKAction repeatActionForever:spawnHalo] withKey:@"SpawnHalo"];
        
        // Screate spawn shield power up action.
        SKAction *spawnShieldPowerUp = [SKAction sequence:@[[SKAction waitForDuration:10 withRange:4],
                                                            [SKAction performSelector:@selector(spawnShieldPowerUp) onTarget:self]]];
        [self runAction:[SKAction repeatActionForever:spawnShieldPowerUp]];
        
        SKAction *spawnExplosiveBarrel = [SKAction sequence:@[[SKAction waitForDuration:1],
                                                            [SKAction performSelector:@selector(spawnExplosiveBarrel) onTarget:self]]];
        [self runAction:[SKAction repeatActionForever:spawnExplosiveBarrel]];
        
        
        // Setup Ammo.
        _ammoDisplay = [SKSpriteNode spriteNodeWithImageNamed:@"Ammo5"];
        _ammoDisplay.anchorPoint = CGPointMake(0.5, 0.0);
        _ammoDisplay.position = _cannon.position;
        [self addChild:_ammoDisplay];
        
        SKAction *incrementAmmo;
        
        incrementAmmo = [SKAction sequence:@[[SKAction waitForDuration:0.95],
                                             [SKAction runBlock:^{
            self.ammo++;
        }]]];
        
        [self runAction:[SKAction repeatActionForever:incrementAmmo]];
        
        // Setup shield pool
        _shieldPool = [[NSMutableArray alloc] init];
        
        // Setup shields
        for (int i = 0; i < 6; i++) {
            SKSpriteNode *shield = [SKSpriteNode spriteNodeWithImageNamed:@"Block"];
            shield.name = @"shield";
            shield.position = CGPointMake(35 + (50 *i), 90);
            shield.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(42, 9)];
            shield.physicsBody.categoryBitMask = kCCShieldCategory;
            shield.physicsBody.collisionBitMask = 0;
            [_shieldPool addObject:shield];
        }
        
        // Setup pause button
        _pauseButton = [SKSpriteNode spriteNodeWithImageNamed:@"PauseButton"];
        _pauseButton.position = CGPointMake(self.size.width - 30, 20);
        [self addChild:_pauseButton];
        
        // Setup resume button
        _resumeButton = [SKSpriteNode spriteNodeWithImageNamed:@"ResumeButton"];
        _resumeButton.position = CGPointMake(self.size.width * 0.5, self.size.height * 0.5);
        [self addChild:_resumeButton];
        
        // Setup score display
        _scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
        _scoreLabel.position = CGPointMake(15, 10);
        _scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
        _scoreLabel.fontSize = 15;
        [self addChild:_scoreLabel];
        
        // Setup point multiplier label
        _pointLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
        _pointLabel.position = CGPointMake(15, 30);
        _pointLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
        _pointLabel.fontSize = 15;
        [self addChild:_pointLabel];
        
        // Setup sounds
        _bounceSound = [SKAction playSoundFileNamed:@"Bounce.caf" waitForCompletion:NO];
        _deepExplosionSound = [SKAction playSoundFileNamed:@"DeepExplosion.caf" waitForCompletion:NO];
        _explosionSound = [SKAction playSoundFileNamed:@"Explosion.caf" waitForCompletion:NO];
        _laserSound = [SKAction playSoundFileNamed:@"Laser.caf" waitForCompletion:NO];
        _zapSound = [SKAction playSoundFileNamed:@"Zap.caf" waitForCompletion:NO];
        _shieldUpSound = [SKAction playSoundFileNamed:@"ShieldUp.caf" waitForCompletion:NO];
        
        // Setup menu
        _menu = [[CCMenu alloc] init];
        _menu.position = CGPointMake(self.size.width * 0.5, self.size.height - 220);
        [self addChild:_menu];
        
        // Set initial values
        self.ammo = 5;
        self.score = 0;
        self.pointValue = 1;
        __gameOver = YES;
        _scoreLabel.hidden = YES;
        _pointLabel.hidden = YES;
        _pauseButton.hidden = YES;
        _resumeButton.hidden = YES;
        _previous_angle = 0.0;
        
        // Load top score
        _userDefaults = [NSUserDefaults standardUserDefaults];
        _menu.topScore = (int)[_userDefaults integerForKey:kCCKeyTopScore];
        
        // Load music
        Music = arc4random_uniform(4);
        NSLog(@"%c",Music);
        if (Music == 0) {
            NSURL *url = [[NSBundle mainBundle] URLForResource:@"ObservingTheStar" withExtension:@"caf"];
            NSError *error = nil;
            _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
            
            if (!_audioPlayer) {
                NSLog(@"Error loading audio player: %@", error);
            }
            else {
                _audioPlayer.numberOfLoops = -1;
                _audioPlayer.volume = 0.8;
                [_audioPlayer play];
                _menu.musicPlaying = YES;
            }
        }
        
        else if (Music == 1){
            NSURL *url = [[NSBundle mainBundle] URLForResource:@"space-tours-to-mars" withExtension:@"m4a"];
            NSError *error = nil;
            _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
            
            if (!_audioPlayer) {
                NSLog(@"Error loading audio player: %@", error);
            }
            else {
                _audioPlayer.numberOfLoops = -1;
                _audioPlayer.volume = 0.8;
                [_audioPlayer play];
                _menu.musicPlaying = YES;
            }
        }
        
        else if (Music == 2){
            NSURL *url = [[NSBundle mainBundle] URLForResource:@"Moon_Landings" withExtension:@"mp3"];
            NSError *error = nil;
            _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
            
            if (!_audioPlayer) {
                NSLog(@"Error loading audio player: %@", error);
            }
            else {
                _audioPlayer.numberOfLoops = -1;
                _audioPlayer.volume = 0.8;
                [_audioPlayer play];
                _menu.musicPlaying = YES;
            }
        }
        
        else if (Music == 3){
            NSURL *url = [[NSBundle mainBundle] URLForResource:@"Space_Adventure" withExtension:@"mp3"];
            NSError *error = nil;
            _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
            
            if (!_audioPlayer) {
                NSLog(@"Error loading audio player: %@", error);
            }
            else {
                _audioPlayer.numberOfLoops = -1;
                _audioPlayer.volume = 0.8;
                [_audioPlayer play];
                _menu.musicPlaying = YES;
            }
        }
        
        
    }
    return self;
}

-(void)newGame
{
    [_mainLayer removeAllChildren];
    
    // Add all shields from pool to scene.
    while (_shieldPool.count > 0) {
        [_mainLayer addChild:[_shieldPool objectAtIndex:0]];
        [_shieldPool removeObjectAtIndex:0];
    }
    
    // Setup life bar
    SKSpriteNode *lifeBar = [SKSpriteNode spriteNodeWithImageNamed:@"BlueBar"];
    lifeBar.position = CGPointMake(self.size.width * 0.5, 70);
    lifeBar.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointMake(-lifeBar.size.width * 0.5, 0) toPoint:CGPointMake(lifeBar.size.width * 0.5, 0)];
    lifeBar.physicsBody.categoryBitMask = kCCLifeBarCategory;
    [_mainLayer addChild:lifeBar];
    
    // Set intial values
    [self actionForKey:@"SpawnHalo"].speed = 1.0;
    self.ammo = 5;
    self.score = 0;
    self.pointValue = 1;
    _scoreLabel.hidden = NO;
    _pointLabel.hidden = NO;
    _pauseButton.hidden = NO;
    [_menu hide];
    __gameOver = NO;
}

-(void)setAmmo:(int)ammo
{
    if (ammo >= 0 && ammo <= 5) {
        _ammo = ammo;
        _ammoDisplay.texture = [SKTexture textureWithImageNamed:[NSString stringWithFormat:@"Ammo%d", ammo]];
    }
}

-(void)setScore:(int)score
{
    _score = score;
    _scoreLabel.text = [NSString stringWithFormat:@"Score: %d", score];
}

-(void)setPointValue:(int)pointValue
{
    _pointValue = pointValue;
    _pointLabel.text = [NSString stringWithFormat:@"Points: x%d", pointValue];
}

-(void)setGamePaused:(BOOL)gamePaused
{
    if (!__gameOver) {
        _gamePaused = gamePaused;
        _pauseButton.hidden = gamePaused;
        _resumeButton.hidden = !gamePaused;
        self.paused = gamePaused;
    }
}

-(void)shoot
{
    if (self.ammo > 0) {
        self.ammo--;
        
        // Create ball node.
        CCBall *ball = [CCBall spriteNodeWithImageNamed:@"Ball"];
        ball.name = @"ball";
        CGVector rotationVector = radiansToVector(_cannon.zRotation);
        ball.position = CGPointMake(_cannon.position.x + (_cannon.size.width * 0.5 * rotationVector.dx),
                                    _cannon.position.y + (_cannon.size.width * 0.5 * rotationVector.dy));
        [_mainLayer addChild:ball];
        
        ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:6.0];
        ball.physicsBody.velocity = CGVectorMake(rotationVector.dx * kCCShootSpeed, rotationVector.dy * kCCShootSpeed);
        ball.physicsBody.restitution = 1.0;
        ball.physicsBody.linearDamping = 0.0;
        ball.physicsBody.friction = 0.0;
        ball.physicsBody.categoryBitMask = kCCBallCategory;
        ball.physicsBody.collisionBitMask = kCCEdgeCategory;
        ball.physicsBody.contactTestBitMask = kCCEdgeCategory | kCCShieldUpCategory;
        [self runAction:_laserSound];
        
        SKAction *rotateBall = [SKAction sequence:@[[SKAction rotateByAngle:M_PI duration:30],
                                                    [SKAction rotateByAngle:-M_PI duration:30]]];
        [ball runAction:[SKAction repeatActionForever:rotateBall]];
        
        // Create trail.
        NSString *ballTrailPath = [[NSBundle mainBundle] pathForResource:@"BallTrail" ofType:@"sks"];
        SKEmitterNode *ballTrail = [NSKeyedUnarchiver unarchiveObjectWithFile:ballTrailPath];
        ballTrail.targetNode = _mainLayer;
        [_mainLayer addChild:ballTrail];
        ball.trail = ballTrail;
    }
    
}

-(void)spawnHalo
{
    // Increase spawn speed.
    SKAction *spawnHaloAction = [self actionForKey:@"SpawnHalo"];
    if (spawnHaloAction.speed < 1.5) {
        spawnHaloAction.speed += 0.01;
    }
    
    // Create halo node.
    SKSpriteNode *halo = [SKSpriteNode spriteNodeWithImageNamed:@"Halo"];
    halo.name = @"halo";
    halo.position = CGPointMake(randomInRange(halo.size.width * 0.5, self.size.width - (halo.size.width * 0.5)),
                                self.size.height + (halo.size.height * 0.5));
    halo.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:16.0];
    CGVector direction = radiansToVector(randomInRange(kCCHaloLowAngle, kCCHaloHighAngle));
    halo.physicsBody.velocity = CGVectorMake(direction.dx * kCCHaloSpeed, direction.dy * kCCHaloSpeed);
    halo.physicsBody.restitution = 1.0;
    halo.physicsBody.affectedByGravity = true;
    halo.physicsBody.mass = 3.0;
    halo.physicsBody.linearDamping = 0.0;
    halo.physicsBody.friction = 0.0;
    halo.physicsBody.categoryBitMask = kCCHaloCategory;
    halo.physicsBody.collisionBitMask = kCCEdgeCategory;
    halo.physicsBody.contactTestBitMask = kCCBallCategory | kCCShieldCategory | kCCLifeBarCategory | kCCEdgeCategory;
    
    
    
    
    
    // Random point multiplier
    if (!__gameOver && arc4random_uniform(12) == 0) {
        halo.texture = [SKTexture textureWithImageNamed:@"HaloX"];
        halo.userData = [[NSMutableDictionary alloc] init];
        [halo.userData setValue:@YES forKey:@"Multiplier"];
        SKAction *rotateBall = [SKAction sequence:@[[SKAction rotateByAngle:144 duration:45.0],
                                                    ]];
        [halo runAction:[SKAction repeatActionForever:rotateBall]];
        
    }
    
    
    [_mainLayer addChild:halo];
}

-(void)spawnShieldPowerUp
{
    if (_shieldPool.count > 0) {
        SKSpriteNode *shieldUp = [SKSpriteNode spriteNodeWithImageNamed:@"Gen"];//change to shield generator
        shieldUp.name = @"shieldUp";
        shieldUp.position = CGPointMake(self.size.width + shieldUp.size.width, randomInRange(150, self.size.height - 100));
        shieldUp.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(42, 9)];
        shieldUp.physicsBody.categoryBitMask = kCCShieldUpCategory;
        shieldUp.physicsBody.collisionBitMask = 0;
        shieldUp.physicsBody.velocity = CGVectorMake(-100, randomInRange(-40, 40));
        shieldUp.physicsBody.angularVelocity = M_PI;
        shieldUp.physicsBody.linearDamping = 0.0;
        shieldUp.physicsBody.angularDamping = 0.0;
        [_mainLayer addChild:shieldUp];
    }
}


-(void)spawnExplosiveBarrel
{
//        SKSpriteNode *shieldUp = [SKSpriteNode spriteNodeWithImageNamed:@"Gen"];//change to shield generator
//        shieldUp.name = @"PlayButton";
//        shieldUp.position = CGPointMake(randomInRange(150, self.size.width - 100), randomInRange(150, self.size.height - 100));
//        shieldUp.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(42, 9)];
//        shieldUp.physicsBody.categoryBitMask = kCCExplodeBarrell;
//        shieldUp.physicsBody.collisionBitMask = 0;
//        shieldUp.physicsBody.velocity = CGVectorMake(-100, randomInRange(-40, 40));
//        shieldUp.physicsBody.angularVelocity = M_PI;
//        shieldUp.physicsBody.linearDamping = 0.0;
//        shieldUp.physicsBody.angularDamping = 0.0;
//      // Create ball node.
//    
//    for (int i=0; i<6; i++) {
//        CCBall *ball = [CCBall spriteNodeWithImageNamed:@"Ball"];
//        ball.name = @"ball";
//        CGVector rotationVector = radiansToVector(2 * M_PI * i);
//        ball.position = CGPointMake(shieldUp.position.x + (shieldUp.size.width * 0.5 * rotationVector.dx),
//                                    shieldUp.position.y + (shieldUp.size.width * 0.5 * rotationVector.dy));
//        [_mainLayer addChild:ball];
//        
//        ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:6.0];
//        ball.physicsBody.velocity = CGVectorMake(rotationVector.dx * kCCShootSpeed, rotationVector.dy * kCCShootSpeed);
//        ball.physicsBody.restitution = 1.0;
//        ball.physicsBody.linearDamping = 0.0;
//        ball.physicsBody.friction = 0.0;
//        ball.physicsBody.categoryBitMask = kCCBallCategory;
//        ball.physicsBody.collisionBitMask = kCCEdgeCategory;
//        ball.physicsBody.contactTestBitMask = kCCEdgeCategory | kCCShieldUpCategory;
//        [self runAction:_laserSound];
//        
//        SKAction *rotateBall = [SKAction sequence:@[[SKAction rotateByAngle:M_PI duration:30],
//                                                    [SKAction rotateByAngle:-M_PI duration:30]]];
//        [ball runAction:[SKAction repeatActionForever:rotateBall]];
//        
//        // Create trail.
//        NSString *ballTrailPath = [[NSBundle mainBundle] pathForResource:@"BallTrail" ofType:@"sks"];
//        SKEmitterNode *ballTrail = [NSKeyedUnarchiver unarchiveObjectWithFile:ballTrailPath];
//        ballTrail.targetNode = _mainLayer;
//        [_mainLayer addChild:ballTrail];
//        ball.trail = ballTrail;
//    }

}

-(void)didBeginContact:(SKPhysicsContact *)contact
{
    SKPhysicsBody *firstBody;
    SKPhysicsBody *secondBody;
    
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask) {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    } else {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    
    if (firstBody.categoryBitMask == kCCHaloCategory && secondBody.categoryBitMask == kCCBallCategory) {
        // Collision between halo and ball.
        self.score += self.pointValue;
        [self addExplosion:firstBody.node.position withName:@"HaloExplosion"];
        [self runAction:_explosionSound];
        
        if ([[firstBody.node.userData valueForKey:@"Multiplier"] boolValue]) {
            self.pointValue = self.pointValue + 10;
        }
        
        firstBody.categoryBitMask = 0;
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
    }
    if (firstBody.categoryBitMask == kCCHaloCategory && secondBody.categoryBitMask == kCCShieldCategory) {
        // Collision between halo and shield.
        [self addExplosion:firstBody.node.position withName:@"HaloExplosion"];
        [self runAction:_explosionSound];
        
        firstBody.categoryBitMask = 0;
        [firstBody.node removeFromParent];
        [_shieldPool addObject:secondBody.node];
        [secondBody.node removeFromParent];
    }
    if (firstBody.categoryBitMask == kCCHaloCategory && secondBody.categoryBitMask == kCCLifeBarCategory) {
        // Collision between halo and life bar.
        [self addExplosion:secondBody.node.position withName:@"LifeBarExplosion"];
        [self runAction:_deepExplosionSound];
        
        firstBody.categoryBitMask = 0;
        [secondBody.node removeFromParent];
        [self gameOver];
    }
    if (firstBody.categoryBitMask == kCCHaloCategory && secondBody.categoryBitMask == kCCEdgeCategory) {
        [self runAction:_zapSound];
    }
    if (firstBody.categoryBitMask == kCCBallCategory && secondBody.categoryBitMask == kCCEdgeCategory) {
        if ([firstBody.node isKindOfClass:[CCBall class]]) {
            ((CCBall*)firstBody.node).bounces++;
            if (((CCBall*)firstBody.node).bounces > 3) {
                [firstBody.node removeFromParent];
                self.pointValue = 1;
            }
        }
        
        [self runAction:_bounceSound];
    }
    if (firstBody.categoryBitMask == kCCBallCategory && secondBody.categoryBitMask == kCCShieldUpCategory) {
        // Hit a shield power up.
        if (_shieldPool.count > 0 ) {
            int randomIndex = arc4random_uniform((int)_shieldPool.count);
            [_mainLayer addChild:[_shieldPool objectAtIndex:randomIndex]];
            [_shieldPool removeObjectAtIndex:randomIndex];
            [self runAction:_shieldUpSound];
        }
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
    }
    
    
}

-(void)gameOver
{
    [_mainLayer enumerateChildNodesWithName:@"halo" usingBlock:^(SKNode *node, BOOL *stop) {
        [self addExplosion:node.position withName:@"HaloExplosion"];
        [node removeFromParent];
    }];
    [_mainLayer enumerateChildNodesWithName:@"ball" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeFromParent];
    }];
    [_mainLayer enumerateChildNodesWithName:@"shield" usingBlock:^(SKNode *node, BOOL *stop) {
        [_shieldPool addObject:node];
        [node removeFromParent];
    }];
    [_mainLayer enumerateChildNodesWithName:@"shieldUp" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeFromParent];
    }];
    
    _menu.score = self.score;
    if (self.score > _menu.topScore) {
        _menu.topScore = self.score;
        [_userDefaults setInteger:self.score forKey:kCCKeyTopScore];
        [_userDefaults synchronize];
    }
    __gameOver = YES;//chamge to yes
    _scoreLabel.hidden = YES;
    _pointLabel.hidden = YES;
    _pauseButton.hidden = YES;
    [self runAction:[SKAction waitForDuration:1.0] completion:^{
        [_menu show];
    }];
    
    
}
-(void)addExplosion:(CGPoint)position withName:(NSString*)name
{
    NSString *explosionPath = [[NSBundle mainBundle] pathForResource:name ofType:@"sks"];
    SKEmitterNode *explosion = [NSKeyedUnarchiver unarchiveObjectWithFile:explosionPath];
    
    explosion.position = position;
    [_mainLayer addChild:explosion];
    
    SKAction *removeExplosion = [SKAction sequence:@[[SKAction waitForDuration:1.5],
                                                     [SKAction removeFromParent]]];
    [explosion runAction:removeExplosion];
    
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *theTouch = [touches anyObject];
    _startPoint = [theTouch locationInView:self.view];
    
    SKAction *rotateCannon;
    
    CGFloat x = _startPoint.x;
    CGFloat y = self.size.height -(_startPoint.y);
    
    CGFloat b = _cannon.position.x; // to become viewcontroller width
    CGFloat a = sqrtf(powf((x-b), 2.0)+powf((y-0.0), 2.0));
    CGFloat c = sqrtf(powf((x-0.0), 2.0)+powf((y-0.0), 2.0));
    CGFloat C2;
    CGFloat C = C2 = M_PI - fabs(acosf((powf(a, 2.0)+(powf(b, 2.0)-(powf(c, 2.0))))/(2*a*b)));
    _isMoving = true;
    
    if (C<_previous_angle) {
        C =  -1 * (_previous_angle - C);
        rotateCannon = [SKAction sequence:@[[SKAction rotateByAngle:C duration:(fabs(C)/M_PI)*1.15]]];
        
    }
    
    if(C > _previous_angle){
        C = C - _previous_angle;
        rotateCannon = [SKAction sequence:@[[SKAction rotateByAngle:C duration:(C/M_PI)*1.15]]];
        
        
    }
    
    [_cannon runAction:rotateCannon];
    [NSTimer scheduledTimerWithTimeInterval:(fabs(C)/M_PI)*2
                                     target:self
                                   selector:@selector(WaitTimerIsUp:)
                                   userInfo:nil
                                    repeats:NO];
    _isMoving = false;
    _previous_angle = C2;
    
}
- (void) WaitTimerIsUp:(NSTimer*)t {
    
    _isMoving = false;
    if (!__gameOver && !self.gamePaused && !_isMoving) {
        _didShoot = YES;
    }
    
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        if (__gameOver && _menu.touchable) {
            SKNode *n = [_menu nodeAtPoint:[touch locationInNode:_menu]];
            if ([n.name isEqualToString:@"Play"]) {
                [self newGame];
            }
            if ([n.name isEqualToString:@"Music"]) {
                _menu.musicPlaying = !_menu.musicPlaying;
                if (_menu.musicPlaying) {
                    [_audioPlayer play];
                } else {
                    [_audioPlayer stop];
                }
            }
        }
        else if (!__gameOver)
        {
            if (self.gamePaused) {
                if ([_resumeButton containsPoint:[touch locationInNode:_resumeButton.parent]]) {
                    self.gamePaused = NO;
                }
            } else {
                if ([_pauseButton containsPoint:[touch locationInNode:_pauseButton.parent]]) {
                    self.gamePaused = YES;
                }
            }
        }
    }
}

-(void)didSimulatePhysics
{
    // Shoot.
    if (_didShoot) {
        [self shoot];
        _didShoot = NO;
    }
    
    // Remove unused nodes.
    [_mainLayer enumerateChildNodesWithName:@"ball" usingBlock:^(SKNode *node, BOOL *stop) {
        if ([node respondsToSelector:@selector(updateTrail)]) {
            [node performSelector:@selector(updateTrail) withObject:nil afterDelay:0.0];
        }
        
        if (!CGRectContainsPoint(self.frame, node.position)) {
            [node removeFromParent];
            self.pointValue = 1;
        }
    }];
    
    [_mainLayer enumerateChildNodesWithName:@"shieldUp" usingBlock:^(SKNode *node, BOOL *stop) {
        if (node.position.x + node.frame.size.width < 0) {
            [node removeFromParent];
        }
    }];
    
    [_mainLayer enumerateChildNodesWithName:@"halo" usingBlock:^(SKNode *node, BOOL *stop) {
        if (node.position.y + node.frame.size.height < 0) {
            [node removeFromParent];
        }
    }];
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

@end



