//
//  GameScene.swift
//  firstGame
//
//  Created by sbc on 2018/08/09.
//  Copyright © 2018年 cpi. All rights reserved.
//

import SpriteKit
import GameplayKit

let birdCategory: UInt32 =  0x1 << 0
let pipeCategory: UInt32 =  0x1 << 1
let floorCategory: UInt32 = 0x1 << 2

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    private let stageUpScore = 1 
    private var upFlag = false
    private var cnt = 0
    
    private var floor1 : SKSpriteNode!
    private var floor2 : SKSpriteNode!
    private var bird : SKSpriteNode!
    private var upPipe : SKSpriteNode!
    private var downPipe : SKSpriteNode!
    
    lazy var gameOverLabel:SKLabelNode = {
        let label = SKLabelNode(fontNamed: "Chalkduster")
        label.text = "Game Over"
        return label
    }()
    
//    lazy var meterLabel:SKLabelNode = {
//        let label = SKLabelNode(text: "meters:0")
//        label.verticalAlignmentMode = .top
//        label.horizontalAlignmentMode = .center
//        return label
//    }()
//
//    var meter = 0 {
//        didSet {
//            meterLabel.text = "meter:\(meter)"
//        }
//    }
    
//    private var scoreLabel : SKLabelNode!
//    private var score = 0
    lazy var scoreLabel: SKLabelNode = {
        let label = SKLabelNode(text: "score:0")
        return label
    }()
    
    var score = 0 {
        didSet {
            scoreLabel.text = "score:\(score)"

        }
    }
    
    //sound
    let gameoverSound = SKAction.playSoundFileNamed("over.wav", waitForCompletion: false)
    let flapSound = SKAction.playSoundFileNamed("flapping.wav", waitForCompletion: false)
    
    enum GameStatus {
        case idle
        case run1
        case run2
        case over
    }
    private var gameStatus : GameStatus = .idle
    
    override func didMove(to view: SKView) {
        
        self.backgroundColor = SKColor(red: 80.0/255.0, green: 192.0/255.0, blue: 203.0/255.0, alpha: 1.0)
        
        //set scene physics
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        self.physicsWorld.contactDelegate = self
        
        // Set floor
        floor1 = SKSpriteNode(imageNamed: "floor")
        floor1.anchorPoint = CGPoint(x: 0, y: 0)
        floor1.position = CGPoint(x: 0, y: 0)
        
        //set floor1 physics
        floor1.physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(x: 0, y: 0, width: floor1.size.width, height: floor1.size.height))
        floor1.physicsBody?.categoryBitMask = floorCategory
        floor1.physicsBody?.contactTestBitMask = birdCategory
        
        addChild(floor1)
        
        floor2 = SKSpriteNode(imageNamed: "floor")
        floor2.anchorPoint = CGPoint(x: 0, y: 0)
        floor2.position = CGPoint(x: floor1.size.width, y: 0)
        
        //set floor2 physics
        floor2.physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(x: 0, y: 0, width: floor2.size.width, height: floor2.size.height))
        floor2.physicsBody?.categoryBitMask = floorCategory
        floor2.physicsBody?.contactTestBitMask = birdCategory
        
        addChild(floor2)
        
        bird = SKSpriteNode(imageNamed: "player1")
        //set bird physics
        bird.physicsBody = SKPhysicsBody(texture: bird.texture!, size: bird.size)
        bird.physicsBody?.allowsRotation = false//can't rotation
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.contactTestBitMask = floorCategory | pipeCategory

        addChild(bird)
        
        //set meter label
//        meterLabel.position = CGPoint(x: self.size.width*0.5, y: self.size.height)
//        meterLabel.zPosition = 100
//        addChild(meterLabel)
        
        //set score label
        scoreLabel.position = CGPoint(x: self.size.width*0.5, y: 0)
        addChild(scoreLabel)
        shuffle()
        
    }
    
    //start flying
    func birdStartFly() {
        let flyAction = SKAction.animate(with: [SKTexture(imageNamed:"player1"),SKTexture(imageNamed:"player2"),SKTexture(imageNamed:"player3"),SKTexture(imageNamed:"player2")], timePerFrame: 0.15)
        bird.run(SKAction.repeatForever(flyAction), withKey: "fly")
    }
    
    //stop flying
    func birdStopFly() {
        bird.removeAction(forKey: "fly")
    }
    
    //create pipe
    func addPipe(upSize: CGSize, downSize: CGSize) {
        //create pipeup
        let upTexture = SKTexture(imageNamed: "pipeup")
        upPipe = SKSpriteNode(texture: upTexture, size: upSize)
        upPipe.name = "upPipe"
        
        if gameStatus == .run1 {
            upPipe.position = CGPoint(x: self.size.width + upPipe.size.width*0.5, y: self.size.height - upPipe.size.height*0.5)
        }else if gameStatus == .run2 {
            upPipe.position = CGPoint(x: self.size.width + upPipe.size.width*0.5, y: self.size.height+200 - (upPipe.size.height-200)*0.5)
        }
        
        //create pipedown
        let downTexture = SKTexture(imageNamed: "pipedown")
        downPipe = SKSpriteNode(texture: downTexture, size: downSize)
        downPipe.name = "downPipe"
        downPipe.position = CGPoint(x: self.size.width + downPipe.size.width*0.5, y: self.floor1.size.height + downPipe.size.height*0.5)
        
        //set pipe physics
        upPipe.physicsBody = SKPhysicsBody(texture: upTexture, size: upSize)
        upPipe.physicsBody?.isDynamic = false
        upPipe.physicsBody?.categoryBitMask = pipeCategory
        
        downPipe.physicsBody = SKPhysicsBody(texture: downTexture, size: downSize)
        downPipe.physicsBody?.isDynamic = false
        downPipe.physicsBody?.categoryBitMask = pipeCategory
        
        addChild(upPipe)
        addChild(downPipe)
        downPipe.userData = NSMutableDictionary()
    }
    
    //create random pipe
    func createRandomPipe(gapMultiple: Int) {
        print("bird.size.height",bird.size.height);
        print("bird.size.width",bird.size.width)
        print("self.size.height",self.size.height);
        print("self.size.width",self.size.width)
        print("floor1.size.height",floor1.size.height);
        print("floor1.size.width",floor1.size.width)
        
        //the height from floor to top
        let height = self.size.height - self.floor1.size.height
        
        //the gap instance between pipeup and pipedown
        let pipeGap = CGFloat(arc4random_uniform(UInt32(bird.size.height))) + bird.size.height * CGFloat(gapMultiple)
        //you can change the width of pipe if necessary.here is fixed
        let pipeWidth = CGFloat(20.0)
        
        //calculate the height of pipeup and pipedown
        let upPipeHeight = CGFloat(arc4random_uniform(UInt32(height - pipeGap)))
        let downPipeHeight = height - pipeGap - upPipeHeight
        
        if gameStatus == .run1 {
            addPipe(upSize: CGSize(width: pipeWidth, height: upPipeHeight), downSize: CGSize(width: pipeWidth, height: downPipeHeight))
        }
        if gameStatus == .run2 {
            addPipe(upSize: CGSize(width: pipeWidth, height: upPipeHeight+200), downSize: CGSize(width: pipeWidth, height: downPipeHeight))
        }
    }
    
    func startCreateRandomPipeAction(gapMultiple: Int) {
        //wait for the action, the average wait time is 3.5s,the range of change is 1s
//        let waitAct = SKAction.wait(forDuration: 3.5, withRange: 1.0)
        let waitAct = SKAction.wait(forDuration: 3)
        let generatePipeAct = SKAction.run {
            self.createRandomPipe(gapMultiple: Int(gapMultiple))
        }
        run(SKAction.repeatForever(SKAction.sequence([waitAct,generatePipeAct])), withKey: "createPipe")
    }
    
    func stopCreateRandomPipeAction() {
        self.removeAction(forKey: "createPipe")
    }
    
    func removeAllPipeNode() {
        for pipe in self.children where pipe.name == "upPipe" {
            //remove all pipes created by the game
            pipe.removeFromParent()
        }
        for pipe in self.children where pipe.name == "downPipe" {
            //remove all pipes created by the game
            pipe.removeFromParent()
        }
    }
    
    func shuffle() {
        //init game
        gameStatus = .idle
        self.backgroundColor = SKColor(red: 80.0/255.0, green: 192.0/255.0, blue: 203.0/255.0, alpha: 1.0)
        
        //set the startline of the bird
        bird.position = CGPoint(x: self.size.width*0.5, y: self.size.height*0.5)
        bird.physicsBody?.isDynamic = false
        
        birdStartFly()
        
        removeAllPipeNode()
        gameOverLabel.removeFromParent()
//        meter = 0
        score = 0
    }
    
    func startGame() {
        //start game
        gameStatus = .run1
        bird.physicsBody?.isDynamic = true
        startCreateRandomPipeAction(gapMultiple: Int(7))
    }
    
    func gameOver() {
        //finish game
        gameStatus = .over
        run(gameoverSound)
        
        birdStopFly()
        stopCreateRandomPipeAction()
        
        //stop user tap
        isUserInteractionEnabled = false
        //add gameover label to scene
        addChild(gameOverLabel)
        //put gameover label to the top of the screen
        gameOverLabel.position = CGPoint(x: self.size.width*0.5, y: self.size.height)
        //move gameover label to the middle of the screen
        gameOverLabel.run(SKAction.move(by: CGVector(dx: 0, dy: -self.size.height*0.5), duration: 0.5), completion: {
            //user can tap the screen only after finishing the movement of label
            self.isUserInteractionEnabled = true
        })
    }
    
    func gameStageUp()
    {
        gameStatus = .run2
        removeAllPipeNode()
        //stopCreateRandomPipeAction()
        startCreateRandomPipeAction(gapMultiple: Int(4))
        self.backgroundColor = SKColor(red: 0.0/255.0, green: 18.0/255.0, blue: 193.0/255.0, alpha: 1.0)
    }
    
    
    func moveScene() {
        
        //make floor move
        floor1.position = CGPoint(x: floor1.position.x-1, y: floor1.position.y)
        floor2.position = CGPoint(x: floor2.position.x-1, y: floor2.position.y)
        
        //check floor position
        if floor1.position.x < -floor1.size.width {
            floor1.position = CGPoint(x: floor2.position.x + floor2.size.width, y: floor1.position.y)
        }
        
        if floor2.position.x < -floor2.size.width {
            floor2.position = CGPoint(x: floor1.position.x + floor1.size.width, y: floor2.position.y)
        }
        
        //make pipe move
        for pipeNode in self.children where pipeNode.name == "upPipe" {
            if let pipeSprite = pipeNode as? SKSpriteNode {
                //move pipe to left
//                pipeSprite.position = CGPoint(x: pipeSprite.position.x-1, y: pipeSprite.position.y)
                
                if gameStatus == .run1 {
                    pipeSprite.position = CGPoint(x: pipeSprite.position.x-1, y: pipeSprite.position.y)
                }else if gameStatus == .run2 && upFlag == false {
                    pipeSprite.position = CGPoint(x: pipeSprite.position.x-1, y: pipeSprite.position.y-2)
                    cnt += 1
                    if cnt == 100{
                        cnt = 0
                        upFlag = true
                    }
                }else if gameStatus == .run2 && upFlag == true {
                    pipeSprite.position = CGPoint(x: pipeSprite.position.x-1, y: pipeSprite.position.y+2)
                    cnt += 1
                    if cnt == 80{
                        cnt = 0
                        upFlag = false
                    }
                }
                
                //check the pipe if pipes move out of the left edge
                //if pipes are out of the left edge remove form scene
                if pipeSprite.position.x < -pipeSprite.size.width*0.5 {
                    pipeSprite.removeFromParent()
                }
            }
        }
        for pipeNode in self.children where pipeNode.name == "downPipe" {
            if let pipeSprite = pipeNode as? SKSpriteNode {
                //move pipe to left
                pipeSprite.position = CGPoint(x: pipeSprite.position.x-1, y: pipeSprite.position.y)
     
                //check the pipe if pipes move out of the left edge
                //if pipes are out of the left edge remove form scene
                if pipeSprite.position.x < -pipeSprite.size.width*0.5 {
                    pipeSprite.removeFromParent()
                }
            }
        }
        
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        print("gameStatus", gameStatus)
        if gameStatus != .run1 && gameStatus != .run2 {return}
        
        var bodyA: SKPhysicsBody//small
        var bodyB: SKPhysicsBody//big
        
        print("contact.bodyA.categoryBitMask", contact.bodyA.categoryBitMask)
        print("contact.bodyB.categoryBitMask", contact.bodyB.categoryBitMask)
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            bodyA = contact.bodyA
            bodyB = contact.bodyB
        }else{
            bodyA = contact.bodyB
            bodyB = contact.bodyA
        }
        
        print("bodyA.contactTestBitMask", bodyA.contactTestBitMask)
        print("bodyB.contactTestBitMask", bodyB.contactTestBitMask)
        
//        if(bodyA.categoryBitMask == birdCategory && bodyB.categoryBitMask == pipeCategory) ||(bodyA.categoryBitMask == birdCategory && bodyB.categoryBitMask == floorCategory) {
        if(bodyA.categoryBitMask == birdCategory && bodyB.categoryBitMask == pipeCategory){
            print("gameOver")
            gameOver()
        }
    }
    
    func updateScore() {
        self.enumerateChildNodes(withName: "downPipe", using: {node, stop in
            if let tmpPipe = node as? SKSpriteNode {
                if let passed = tmpPipe.userData?["Passed"] as? NSNumber {
                    if passed.boolValue {
                        print("passed")
                        return
                    }
                }

                if self.bird.position.x > tmpPipe.position.x + tmpPipe.size.width+30 {
                    self.score += 1
                    self.scoreLabel.text = "score:\(self.score)"
                    print("score:", self.score)
                    tmpPipe.userData?["Passed"] = NSNumber(booleanLiteral: true)
                }
            }
        })
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch gameStatus {
        case .idle:
            startGame()
        case .run1:
            print("help the bird fly up")
            run(flapSound)
            bird.physicsBody?.applyImpulse(CGVector(dx:0,dy:20))
        case .run2:
            run(flapSound)
            bird.physicsBody?.applyImpulse(CGVector(dx:0,dy:20))
        case .over:
            shuffle()
        }
    }

    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        if gameStatus != .over {
            
        }
        if gameStatus == .run1 || gameStatus == .run2 {
//            meter += 1
            moveScene()
            updateScore()
        }
        if gameStatus == .run1 && score == stageUpScore {
            gameStageUp()
        }
    }
    

}

