//
//  ViewController.swift
//  TranscriptionApp
//
//  Created by Vaibhav on 15/07/24.
//

import UIKit
import AVKit

class ViewController: UIViewController {
    
    private var videoPlayer: VideoPlayer?
    private var transcription: Transcription?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupStartButton()
    }
    
    private func setupStartButton() {
        let startButton = UIButton()
        startButton.setTitle("Play Video", for: .normal)
        startButton.backgroundColor = .darkGray
        startButton.addTarget(self, action: #selector(startButtonClicked), for: .touchUpInside)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(startButton)
        
        NSLayoutConstraint.activate([
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    @objc private func startButtonClicked() {
        videoPlayer = VideoPlayer(in: self)
        transcription = Transcription(in: self)
        
        videoPlayer?.setupPlayer()
        transcription?.setup()
        
        videoPlayer?.player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: .main) { [weak self] time in
            self?.transcription?.updateTranscription(for: time.seconds)
        }
        
        videoPlayer?.player?.play()
    }
}
