//
//  GameScene.swift
//  FlappyBird
//
//  Created by Nate Murray on 6/2/14.
//  Copyright (c) 2014 Fullstack.io. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate{
    let verticalPipeGap = 150.0
    
    var bird:SKSpriteNode!
    var skyColor:SKColor!
    var pipeTextureUp:SKTexture!
    var pipeTextureDown:SKTexture!
    var movePipesAndRemove:SKAction!
    var moving:SKNode!
    var pipes:SKNode!
    var canRestart = Bool()
    var scoreLabelNode:SKLabelNode!
    var score = NSInteger()
    var highScore = NSInteger()
    var screenshot: UIImage!
    var scoreboard: UIImageView!
    var resetButton: UIButton!
    var shareButton: UIButton!
    var scoreLabel: UILabel!
    var highScoreLabel: UILabel!
    var medalLabel: UILabel!
    
    let birdCategory: UInt32 = 1 << 0
    let worldCategory: UInt32 = 1 << 1
    let pipeCategory: UInt32 = 1 << 2
    let scoreCategory: UInt32 = 1 << 3
    
    override func didMove(to view: SKView) {
        
        canRestart = true
        
        // setup physics
        self.physicsWorld.gravity = CGVector( dx: 0.0, dy: -5.0 )
        self.physicsWorld.contactDelegate = self
        
        // setup background color
        skyColor = SKColor(red: 81.0/255.0, green: 192.0/255.0, blue: 201.0/255.0, alpha: 1.0)
        self.backgroundColor = skyColor
        
        moving = SKNode()
        self.addChild(moving)
        pipes = SKNode()
        moving.addChild(pipes)
        
        // ground
        let groundTexture = SKTexture(imageNamed: "land")
        groundTexture.filteringMode = .nearest // shorter form for SKTextureFilteringMode.Nearest
        
        let moveGroundSprite = SKAction.moveBy(x: -groundTexture.size().width * 2.0, y: 0, duration: TimeInterval(0.02 * groundTexture.size().width * 2.0))
        let resetGroundSprite = SKAction.moveBy(x: groundTexture.size().width * 2.0, y: 0, duration: 0.0)
        let moveGroundSpritesForever = SKAction.repeatForever(SKAction.sequence([moveGroundSprite,resetGroundSprite]))
        
        for i in 0 ..< 2 + Int(self.frame.size.width / ( groundTexture.size().width * 2 )) {
            let i = CGFloat(i)
            let sprite = SKSpriteNode(texture: groundTexture)
            sprite.setScale(2.0)
            sprite.position = CGPoint(x: i * sprite.size.width, y: sprite.size.height / 2.0)
            sprite.run(moveGroundSpritesForever)
            moving.addChild(sprite)
        }
        
        // skyline
        let skyTexture = SKTexture(imageNamed: "sky")
        skyTexture.filteringMode = .nearest
        
        let moveSkySprite = SKAction.moveBy(x: -skyTexture.size().width * 2.0, y: 0, duration: TimeInterval(0.1 * skyTexture.size().width * 2.0))
        let resetSkySprite = SKAction.moveBy(x: skyTexture.size().width * 2.0, y: 0, duration: 0.0)
        let moveSkySpritesForever = SKAction.repeatForever(SKAction.sequence([moveSkySprite,resetSkySprite]))
        
        for i in 0 ..< 2 + Int(self.frame.size.width / ( skyTexture.size().width * 2 )) {
            let i = CGFloat(i)
            let sprite = SKSpriteNode(texture: skyTexture)
            sprite.setScale(2.0)
            sprite.zPosition = -20
            sprite.position = CGPoint(x: i * sprite.size.width, y: sprite.size.height / 2.0 + groundTexture.size().height * 2.0)
            sprite.run(moveSkySpritesForever)
            moving.addChild(sprite)
        }
        
        // create the pipes textures
        pipeTextureUp = SKTexture(imageNamed: "PipeUp")
        pipeTextureUp.filteringMode = .nearest
        pipeTextureDown = SKTexture(imageNamed: "PipeDown")
        pipeTextureDown.filteringMode = .nearest
        
        // create the pipes movement actions
        let distanceToMove = CGFloat(self.frame.size.width + 2.0 * pipeTextureUp.size().width)
        let movePipes = SKAction.moveBy(x: -distanceToMove, y:0.0, duration:TimeInterval(0.01 * distanceToMove))
        let removePipes = SKAction.removeFromParent()
        movePipesAndRemove = SKAction.sequence([movePipes, removePipes])
        
        // spawn the pipes
        let spawn = SKAction.run(spawnPipes)
        let delay = SKAction.wait(forDuration: TimeInterval(2.0))
        let spawnThenDelay = SKAction.sequence([spawn, delay])
        let spawnThenDelayForever = SKAction.repeatForever(spawnThenDelay)
        self.run(spawnThenDelayForever)
        
        // setup our bird
        let birdTexture1 = SKTexture(imageNamed: "bird-01")
        birdTexture1.filteringMode = .nearest
        let birdTexture2 = SKTexture(imageNamed: "bird-02")
        birdTexture2.filteringMode = .nearest
        
        let anim = SKAction.animate(with: [birdTexture1, birdTexture2], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(anim)
        
        bird = SKSpriteNode(texture: birdTexture1)
        bird.setScale(2.0)
        bird.position = CGPoint(x: self.frame.size.width * 0.35, y:self.frame.size.height * 0.6)
        bird.run(flap)
        
        
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)
        bird.physicsBody?.isDynamic = true
        bird.physicsBody?.allowsRotation = false
        
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = worldCategory | pipeCategory
        bird.physicsBody?.contactTestBitMask = worldCategory | pipeCategory
        
        self.addChild(bird)
        
        // create the ground
        let ground = SKNode()
        ground.position = CGPoint(x: 0, y: groundTexture.size().height)
        ground.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.frame.size.width, height: groundTexture.size().height * 2.0))
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = worldCategory
        self.addChild(ground)
        
        // Initialize label and create a label which holds the score
        score = 0
        scoreLabelNode = SKLabelNode(fontNamed:"MarkerFelt-Wide")
        scoreLabelNode.position = CGPoint( x: self.frame.midX, y: 3 * self.frame.size.height / 4 )
        scoreLabelNode.zPosition = 100
        scoreLabelNode.text = String(score)
        self.addChild(scoreLabelNode)
        
        // set up scoreboard/buttons
        self.scoreboard = UIImageView(image: UIImage(named: "scoreboard"))
        self.view?.addSubview(self.scoreboard)
        
        self.resetButton = UIButton(frame: CGRect(x: 0, y: 0, width: 120, height: 50))
        self.resetButton.setBackgroundImage(UIImage(named: "reset"), for: .normal)
        self.view?.addSubview(self.resetButton)
        
        self.shareButton = UIButton(frame: CGRect(x: 0, y: 0, width: 120, height: 50))
        self.shareButton.setBackgroundImage(UIImage(named: "share"), for: .normal)
        self.view?.addSubview(self.shareButton)
        
        // add constraints to buttons/scoreboard
        
        self.scoreboard.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: self.scoreboard, attribute: .centerX, relatedBy: .equal, toItem: self.view!, attribute: .centerX, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: self.scoreboard, attribute: .centerY, relatedBy: .equal, toItem: self.view!, attribute: .centerY, multiplier: 1, constant: 0).isActive = true
        
        self.resetButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: self.resetButton, attribute: .leading, relatedBy: .equal, toItem: self.scoreboard, attribute: .leading, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: self.resetButton, attribute: .top, relatedBy: .equal, toItem: self.scoreboard, attribute: .bottom, multiplier: 1, constant: -70).isActive = true
        NSLayoutConstraint(item: self.resetButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 120).isActive = true
        NSLayoutConstraint(item: self.resetButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 50).isActive = true
        
        self.shareButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: self.shareButton, attribute: .trailing, relatedBy: .equal, toItem: self.scoreboard, attribute: .trailing, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: self.shareButton, attribute: .top, relatedBy: .equal, toItem: self.scoreboard, attribute: .bottom, multiplier: 1, constant: -70).isActive = true
        NSLayoutConstraint(item: self.shareButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 120).isActive = true
        NSLayoutConstraint(item: self.shareButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 50).isActive = true
        
        // add target function to buttons
        self.resetButton.addTarget(self, action: #selector(self.buttonTapped(sender:)), for: .touchUpInside)
        self.shareButton.addTarget(self, action: #selector(self.buttonTapped(sender:)), for: .touchUpInside)
        
        // add tags to buttons
        self.resetButton.tag = 2
        self.shareButton.tag = 3
        
        // initialize labels and add them to the scoreboard
        self.scoreLabel = UILabel(frame: CGRect(x: 175, y: 102, width: 50, height: 21))
        scoreLabel.font = UIFont(name: "MarkerFelt-Wide", size: 24)
        scoreLabel.textAlignment = .center
        scoreLabel.text = String(score)
        
        self.highScoreLabel = UILabel(frame: CGRect(x: 175, y: 145, width: 50, height: 21))
        highScoreLabel.font = UIFont(name: "MarkerFelt-Wide", size: 24)
        highScoreLabel.textAlignment = .center
        highScoreLabel.text = String(highScore)
        
        self.medalLabel = UILabel(frame: CGRect(x: 28, y: 106, width: 50, height: 50))
        medalLabel.font = UIFont(name: "MarkerFelt-Wide", size: 48)
        medalLabel.textAlignment = .center
        medalLabel.text = "★"
        
        self.scoreboard.addSubview(self.scoreLabel)
        self.scoreboard.addSubview(self.highScoreLabel)
        self.scoreboard.addSubview(self.medalLabel)
        
        // initially hide the buttons and scoreboard
        self.scoreboard.isHidden = true
        self.resetButton.isHidden = true
        self.shareButton.isHidden = true
        
        // initialize highscore from userDefaults
        self.highScore = UserDefaults.standard.integer(forKey: "highscore")
    }
    
    func spawnPipes() {
        let pipePair = SKNode()
        pipePair.position = CGPoint( x: self.frame.size.width + pipeTextureUp.size().width * 2, y: 0 )
        pipePair.zPosition = -10
        
        let height = UInt32( self.frame.size.height / 4)
        let y = Double(arc4random_uniform(height) + height)
        
        let pipeDown = SKSpriteNode(texture: pipeTextureDown)
        pipeDown.setScale(2.0)
        pipeDown.position = CGPoint(x: 0.0, y: y + Double(pipeDown.size.height) + verticalPipeGap)
        
        
        pipeDown.physicsBody = SKPhysicsBody(rectangleOf: pipeDown.size)
        pipeDown.physicsBody?.isDynamic = false
        pipeDown.physicsBody?.categoryBitMask = pipeCategory
        pipeDown.physicsBody?.contactTestBitMask = birdCategory
        pipePair.addChild(pipeDown)
        
        let pipeUp = SKSpriteNode(texture: pipeTextureUp)
        pipeUp.setScale(2.0)
        pipeUp.position = CGPoint(x: 0.0, y: y)
        
        pipeUp.physicsBody = SKPhysicsBody(rectangleOf: pipeUp.size)
        pipeUp.physicsBody?.isDynamic = false
        pipeUp.physicsBody?.categoryBitMask = pipeCategory
        pipeUp.physicsBody?.contactTestBitMask = birdCategory
        pipePair.addChild(pipeUp)
        
        let contactNode = SKNode()
        contactNode.position = CGPoint( x: pipeDown.size.width + bird.size.width / 2, y: self.frame.midY )
        contactNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize( width: pipeUp.size.width, height: self.frame.size.height ))
        contactNode.physicsBody?.isDynamic = false
        contactNode.physicsBody?.categoryBitMask = scoreCategory
        contactNode.physicsBody?.contactTestBitMask = birdCategory
        pipePair.addChild(contactNode)
        
        pipePair.run(movePipesAndRemove)
        pipes.addChild(pipePair)
        
    }
    
    func resetScene (){
        // Move bird to original position and reset velocity
        bird.position = CGPoint(x: self.frame.size.width / 2.5, y: self.frame.midY)
        bird.physicsBody?.velocity = CGVector( dx: 0, dy: 0 )
        bird.physicsBody?.collisionBitMask = worldCategory | pipeCategory
        bird.speed = 1.0
        bird.zRotation = 0.0
        
        // Remove all existing pipes
        pipes.removeAllChildren()
        
        // Reset _canRestart
        canRestart = false
        
        // Reset score
        score = 0
        scoreLabelNode.text = String(score)
        
        // Restart animation
        moving.speed = 1
        
        // Re-hide scoreboard and buttons
        self.scoreboard.isHidden = true
        self.resetButton.isHidden = true
        self.shareButton.isHidden = true
        
        // un-hide score
        self.scoreLabelNode.isHidden = false
    }
    
    func gameOver() {
        self.screenshot = self.snapshotImage(view: self.view!)
        
        // hide score label above scoreboard
        self.scoreLabelNode.isHidden = true
        
        // save high score if changed
        if score > highScore {
            UserDefaults.standard.set(score, forKey: "highscore")
            highScore = score
        }
        
        // un-hide scoreboard and buttons
        self.scoreboard.isHidden = false
        self.resetButton.isHidden = false
        self.shareButton.isHidden = false
        
        // change scoreboard label values
        self.scoreLabel.text = String(score)
        self.highScoreLabel.text = String(highScore)
        self.medalLabel.text = "★"
        
        if score > 10 {
            self.medalLabel.textColor = UIColor.yellow
        } else if score > 6 && score <= 10 {
            self.medalLabel.textColor = UIColor.lightGray
        } else if score > 3 {
            self.medalLabel.textColor = UIColor.brown
        } else {
            self.medalLabel.textColor = UIColor.black
            self.medalLabel.text = ""
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if moving.speed > 0  {
            for _ in touches { // do we need all touches?
                bird.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 30))
            }
        }/* else if canRestart {
            self.resetScene()
        }*/
    }
    
    override func update(_ currentTime: TimeInterval) {
        /* Called before each frame is rendered */
        let value = bird.physicsBody!.velocity.dy * ( bird.physicsBody!.velocity.dy < 0 ? 0.003 : 0.001 )
        bird.zRotation = min( max(-1, value), 0.5 )
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if moving.speed > 0 {
            if ( contact.bodyA.categoryBitMask & scoreCategory ) == scoreCategory || ( contact.bodyB.categoryBitMask & scoreCategory ) == scoreCategory {
                // Bird has contact with score entity
                score += 1
                scoreLabelNode.text = String(score)
                
                // Add a little visual feedback for the score increment
                scoreLabelNode.run(SKAction.sequence([SKAction.scale(to: 1.5, duration:TimeInterval(0.1)), SKAction.scale(to: 1.0, duration:TimeInterval(0.1))]))
            } else {
                
                self.gameOver()
                
                moving.speed = 0
                
                bird.physicsBody?.collisionBitMask = worldCategory
                bird.run(  SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration:1), completion: {
                    self.bird.speed = 0
                })
                
                // Flash background if contact is detected
                self.removeAction(forKey: "flash")
                self.run(SKAction.sequence([SKAction.repeat(SKAction.sequence([SKAction.run({
                    self.backgroundColor = SKColor(red: 1, green: 0, blue: 0, alpha: 1.0)
                    }),SKAction.wait(forDuration: TimeInterval(0.05)), SKAction.run({
                        self.backgroundColor = self.skyColor
                        }), SKAction.wait(forDuration: TimeInterval(0.05))]), count:4), SKAction.run({
                            self.canRestart = true
                            })]), withKey: "flash")
            }
        }
    }
    
    @objc func buttonTapped(sender: UIButton) {
        if sender.tag == 2 {
            self.resetScene()
        } else if sender.tag == 3 {
            let activityVC = UIActivityViewController(activityItems: [self.screenshot], applicationActivities: nil)
            self.view?.window?.rootViewController?.present(activityVC, animated: true, completion: nil)
        }
    }
    
    func snapshotImage(view: UIView) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, true, 0)
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: false)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}
