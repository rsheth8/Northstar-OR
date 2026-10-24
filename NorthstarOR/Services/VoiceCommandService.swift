import Foundation
import Speech
import AVFoundation

/// Commands the team can say. Always mirrored by big on-screen buttons as a fallback.
enum VoiceCommand: Equatable {
    case complete, skip, confirm

    /// Maps a transcript to a command. Keep phrases short and distinct for a loud room.
    static func parse(_ transcript: String) -> VoiceCommand? {
        let t = transcript.lowercased()
        if t.contains("skip") { return .skip }
        if t.contains("confirm") || t.contains("acknowledge") { return .confirm }
        if t.contains("complete") || t.contains("done") || t.contains("next") { return .complete }
        return nil
    }
}

/// On-device speech recognition so voice works without Wi-Fi.
/// TODO(co-pilot lane): debounce repeated matches from partial results, add a "listening" level meter.
final class VoiceCommandService {
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    var onCommand: ((VoiceCommand) -> Void)?

    func requestPermissions() async -> Bool {
        let speech = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0 == .authorized) }
        }
        let mic = await AVAudioApplication.requestRecordPermission()
        return speech && mic
    }

    func start() throws {
        stop()
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if recognizer?.supportsOnDeviceRecognition == true { request.requiresOnDeviceRecognition = true }
        self.request = request

        let input = audioEngine.inputNode
        input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { buffer, _ in
            request.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()

        task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result, let command = VoiceCommand.parse(result.bestTranscription.formattedString) {
                DispatchQueue.main.async { self.onCommand?(command) }
                // Restart so the next command starts from a fresh transcript.
                DispatchQueue.main.async { try? self.start() }
            }
            if error != nil { DispatchQueue.main.async { self.stop() } }
        }
    }

    func stop() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
    }
}
