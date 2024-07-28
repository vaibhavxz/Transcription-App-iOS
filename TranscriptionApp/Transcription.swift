//
//  Transcript.swift
//  TranscriptionApp
//
//  Created by Vaibhav on 16/07/24.
//

import UIKit

class Transcription {
    weak var viewController: UIViewController?
    private var transcriptionLabel: UILabel?
    private var toggleButton: UIButton?
    private var transcriptionData: [TranscriptionWord] = []
    private var sentences: [TranscriptionSentence] = []
    private var currentSentenceIndex = 0
    private var isTranscriptionVisible = true
    
    init(in viewController: UIViewController) {
        self.viewController = viewController
    }
    
    func setup() {
        setupTranscriptionLabel()
        setupToggleButton()
        loadTranscriptionData()
        setupNotificationObserver()
    }
    
    private func setupTranscriptionLabel() {
        transcriptionLabel = UILabel()
        transcriptionLabel?.textAlignment = .center
        transcriptionLabel?.textColor = .white
        transcriptionLabel?.numberOfLines = 0
        transcriptionLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        
        guard let transcriptionLabel = transcriptionLabel, let view = viewController?.view else { return }
        
        view.addSubview(transcriptionLabel)
        transcriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            transcriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            transcriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            transcriptionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50)
        ])
    }
    
    private func setupToggleButton() {
        toggleButton = UIButton(type: .system)
        toggleButton?.setTitle("Hide Transcription", for: .normal)
        toggleButton?.setTitleColor(.white, for: .normal)
        toggleButton?.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        toggleButton?.layer.cornerRadius = 5
        toggleButton?.addTarget(self, action: #selector(toggleTranscription), for: .touchUpInside)
        
        guard let toggleButton = toggleButton, let view = viewController?.view else { return }
        
        view.addSubview(toggleButton)
        toggleButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toggleButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            toggleButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toggleButton.widthAnchor.constraint(equalToConstant: 150),
            toggleButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func loadTranscriptionData() {
        if let path = Bundle.main.path(forResource: "response", ofType: "json"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
           let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
           let results = json["results"] as? [String: Any],
           let channels = results["channels"] as? [[String: Any]],
           let alternatives = channels.first?["alternatives"] as? [[String: Any]],
           let words = alternatives.first?["words"] as? [[String: Any]],
           let paragraphs = alternatives.first?["paragraphs"] as? [String: Any],
           let paragraphsArray = paragraphs["paragraphs"] as? [[String: Any]] {
            
            transcriptionData = words.compactMap { wordData in
                guard let word = wordData["word"] as? String,
                      let start = wordData["start"] as? Double,
                      let end = wordData["end"] as? Double else {
                    return nil
                }
                return TranscriptionWord(word: word, start: start, end: end)
            }
            
            for paragraph in paragraphsArray {
                if let sentencesArray = paragraph["sentences"] as? [[String: Any]] {
                    for sentenceData in sentencesArray {
                        if let text = sentenceData["text"] as? String,
                           let start = sentenceData["start"] as? Double,
                           let end = sentenceData["end"] as? Double {
                            sentences.append(TranscriptionSentence(text: text, start: start, end: end))
                        }
                    }
                }
            }
        }
    }
    
    func updateTranscription(for time: Double) {
        guard isTranscriptionVisible else { return }
        
        if let sentenceIndex = sentences.firstIndex(where: { time >= $0.start && time <= $0.end }) {
            currentSentenceIndex = sentenceIndex
        } else {
            currentSentenceIndex = sentences.firstIndex(where: { $0.start > time }) ?? 0
        }
        
        if currentSentenceIndex < sentences.count {
            let currentSentence = sentences[currentSentenceIndex]
        
            let wordsInSentence = transcriptionData.filter { $0.start >= currentSentence.start && $0.end <= currentSentence.end }
            let currentWord = wordsInSentence.first { time >= $0.start && time <= $0.end } ??
            wordsInSentence.first { $0.start > time } ??
            wordsInSentence.last
            
            let attributedString = NSMutableAttributedString(string: currentSentence.text)
            
            if let currentWord = currentWord {
                let sentenceWords = currentSentence.text.components(separatedBy: .whitespaces)
                var startIndex = 0
                var wordOccurrence = 0
                
                for word in sentenceWords {
                    let trimmedWord = word.trimmingCharacters(in: .punctuationCharacters)
                    let range = NSRange(location: startIndex, length: word.count)
                    
                    if trimmedWord.lowercased() == currentWord.word.lowercased() {
                        if wordOccurrence == wordsInSentence.filter({ $0.word.lowercased() == currentWord.word.lowercased() && $0.start <= currentWord.start }).count - 1 {
                            attributedString.addAttribute(.backgroundColor, value: UIColor.yellow, range: range)
                            attributedString.addAttribute(.foregroundColor, value: UIColor.black, range: range)
                            break
                        }
                        wordOccurrence += 1
                    }
                    
                    startIndex += word.count + 1
                }
            }
            
            transcriptionLabel?.attributedText = attributedString
        }
    }
    
    @objc private func toggleTranscription() {
        isTranscriptionVisible.toggle()
        transcriptionLabel?.isHidden = !isTranscriptionVisible
        toggleButton?.setTitle(isTranscriptionVisible ? "Hide Transcription" : "Show Transcription", for: .normal)
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleVideoTimeUpdate(_:)), name: .videoTimeUpdated, object: nil)
    }
    
    @objc private func handleVideoTimeUpdate(_ notification: Notification) {
        if let time = notification.userInfo?["time"] as? Double {
            updateTranscription(for: time)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

struct TranscriptionWord {
    let word: String
    let start: Double
    let end: Double
}

struct TranscriptionSentence {
    let text: String
    let start: Double
    let end: Double
}
