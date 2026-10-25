import AVFoundation

extension Notification.Name {
    static let northstarWillSpeak = Notification.Name("northstarWillSpeak")
}

/// Calm spoken alerts. Only for important moments, per the brand voice rules.
final class VoiceAnnouncer: NSObject, AVSpeechSynthesizerDelegate {
    private(set) static var isSpeaking = false

    override init() {
        super.init()
        synth.delegate = self
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Self.isSpeaking = synthesizer.isSpeaking
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Self.isSpeaking = synthesizer.isSpeaking
    }
    private let synth = AVSpeechSynthesizer()

    func say(_ text: String) {
        Self.isSpeaking = true
        NotificationCenter.default.post(name: .northstarWillSpeak, object: nil)
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.48
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synth.speak(utterance)
    }
}
