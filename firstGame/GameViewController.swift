//
//  GameViewController.swift
//  firstGame
//
//  Created by sbc on 2018/08/09.
//  Copyright © 2018年 cpi. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit
import AVFoundation

class GameViewController: UIViewController {

    var BGMPlayer: AVAudioPlayer!
    
    func playBGM(filename: String) {
        let BGMUrl = Bundle.main.url(forResource: filename, withExtension: nil)
        if BGMUrl == nil {
            print("could not find BGM file: \(filename)")
            return
        }
        
        try! BGMPlayer = AVAudioPlayer(contentsOf: BGMUrl!)
        BGMPlayer.numberOfLoops = -1
        BGMPlayer.prepareToPlay()
        BGMPlayer.play()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            // Load the SKScene from 'GameScene.sks'
     
            let scene = GameScene(size: view.bounds.size)
            
            // Set the scale mode to scale to fit the window
            scene.scaleMode = .aspectFill
            
            // Present the scene
            view.presentScene(scene)
            // play background music
            //playBGM(filename: "flapping.wav")
            
            
            view.ignoresSiblingOrder = true
            
            view.showsFPS = true
            view.showsNodeCount = true
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
