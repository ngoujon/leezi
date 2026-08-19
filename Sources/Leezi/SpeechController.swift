import AVFoundation
import Combine

enum VoiceGender: String, CaseIterable, Identifiable {
    case homme = "Homme"
    case femme = "Femme"
    var id: String { rawValue }

    var avGender: AVSpeechSynthesisVoiceGender {
        self == .homme ? .male : .female
    }
}

@MainActor
final class SpeechController: NSObject, ObservableObject {
    @Published var isSpeaking = false
    @Published var isPaused = false
    @Published var progress: Double = 0 // 0...1
    @Published var rate: Float = 0.5 // 0...1, mappé sur AVSpeechUtteranceMinimumSpeechRate...Maximum
    @Published var gender: VoiceGender = .femme

    private let synthesizer = AVSpeechSynthesizer()
    private var words: [String] = []
    private var fullText: String = ""
    private var currentCharOffset: Int = 0 // offset dans fullText où l'utterance en cours a commencé

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func load(text: String) {
        stop()
        fullText = text
        words = text.split(separator: " ").map(String.init)
        currentCharOffset = 0
        progress = 0
    }

    func play() {
        guard !fullText.isEmpty else { return }
        if isPaused {
            synthesizer.continueSpeaking()
            isPaused = false
            isSpeaking = true
            return
        }
        speak(from: currentCharOffset)
    }

    func pause() {
        guard isSpeaking else { return }
        synthesizer.pauseSpeaking(at: .word)
        isPaused = true
        isSpeaking = false
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        isPaused = false
    }

    /// Avance ou recule d'environ `seconds` secondes, estimé via le débit de mots courant.
    func skip(seconds: Double) {
        guard !fullText.isEmpty else { return }
        let wordsPerSecond = wordsPerSecondEstimate()
        let wordDelta = Int((seconds * wordsPerSecond).rounded())
        let wasSpeaking = isSpeaking

        let currentWordIndex = wordIndex(forCharOffset: currentCharOffset)
        let newIndex = max(0, min(words.count, currentWordIndex + wordDelta))
        let newOffset = charOffset(forWordIndex: newIndex)

        synthesizer.stopSpeaking(at: .immediate)
        currentCharOffset = newOffset
        updateProgress()
        if wasSpeaking {
            speak(from: newOffset)
        } else {
            isPaused = false
            isSpeaking = false
        }
    }

    private func speak(from offset: Int) {
        guard offset < fullText.count else { return }
        let startIndex = fullText.index(fullText.startIndex, offsetBy: offset)
        let remaining = String(fullText[startIndex...])
        let utterance = AVSpeechUtterance(string: remaining)
        utterance.rate = AVSpeechUtteranceMinimumSpeechRate
            + rate * (AVSpeechUtteranceMaximumSpeechRate - AVSpeechUtteranceMinimumSpeechRate)
        utterance.voice = pickVoice()
        synthesizer.speak(utterance)
        isSpeaking = true
        isPaused = false
    }

    private func pickVoice() -> AVSpeechSynthesisVoice? {
        let target = gender.avGender
        let candidates = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("fr") && $0.gender == target }
        return candidates.first ?? AVSpeechSynthesisVoice(language: "fr-FR")
    }

    private func wordsPerSecondEstimate() -> Double {
        // ~180 mots/minute au rythme par défaut (rate = 0.5), linéaire avec `rate`.
        let baseWordsPerMinute = 90.0 + Double(rate) * 180.0
        return baseWordsPerMinute / 60.0
    }

    private func wordIndex(forCharOffset offset: Int) -> Int {
        guard offset > 0 else { return 0 }
        let prefixEnd = fullText.index(fullText.startIndex, offsetBy: min(offset, fullText.count))
        let prefix = fullText[fullText.startIndex..<prefixEnd]
        return prefix.split(separator: " ").count
    }

    private func charOffset(forWordIndex index: Int) -> Int {
        guard index > 0 else { return 0 }
        let joined = words.prefix(index).joined(separator: " ")
        return min(joined.count + 1, fullText.count) // +1 pour l'espace suivant
    }

    private func updateProgress() {
        guard !fullText.isEmpty else { progress = 0; return }
        progress = Double(currentCharOffset) / Double(fullText.count)
    }
}

extension SpeechController: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            // characterRange est relatif au texte de l'utterance en cours, qui démarre à currentCharOffset.
            self.updateProgress()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.isPaused = false
            self.currentCharOffset = self.fullText.count
            self.progress = 1
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
}
