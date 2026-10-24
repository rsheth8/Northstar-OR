import AVFoundation

/// Calm spoken alerts. Only for important moments, per the brand voice rules.
final class VoiceAnnouncer {
    private let synth = AVSpeechSynthesizer()

    func say(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.48
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synth.speak(utterance)
    }
}
