//
//  VideoPlayer.swift
//  TranscriptionApp
//
//  Created by Vaibhav on 16/07/24.
//

import UIKit
import AVKit

class VideoPlayer: NSObject {
    weak var viewController: UIViewController?
    var playerViewController: AVPlayerViewController?
    var player: AVPlayer?
    
    init(in viewController: UIViewController) {
        self.viewController = viewController
    }
    
    func setupPlayer() {
        guard let videoURL = Bundle.main.url(forResource: "IMG_5534", withExtension: "MOV") else {
            print("Video file not found in bundle")
            return
        }
        
        player = AVPlayer(url: videoURL)
        playerViewController = AVPlayerViewController()
        playerViewController?.player = player
        playerViewController?.showsPlaybackControls = true
        
        if let playerView = playerViewController?.view, let viewController = viewController {
            viewController.addChild(playerViewController!)
            viewController.view.addSubview(playerView)
            playerView.frame = viewController.view.bounds
            playerViewController?.didMove(toParent: viewController)
        }
        
        setupObservers()
    }
    
    private func setupObservers() {
        player?.addObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus), options: [.old, .new], context: nil)
        player?.addObserver(self, forKeyPath: #keyPath(AVPlayer.rate), options: [.old, .new], context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AVPlayer.timeControlStatus) || keyPath == #keyPath(AVPlayer.rate) {
            DispatchQueue.main.async { [weak self] in
                if let player = self?.player, let currentItem = player.currentItem {
                    let currentTime = currentItem.currentTime().seconds
                    NotificationCenter.default.post(name: .videoTimeUpdated, object: nil, userInfo: ["time": currentTime])
                }
            }
        }
    }
    
    deinit {
        player?.removeObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus))
        player?.removeObserver(self, forKeyPath: #keyPath(AVPlayer.rate))
    }
}

extension Notification.Name {
    static let videoTimeUpdated = Notification.Name("videoTimeUpdated")
}
