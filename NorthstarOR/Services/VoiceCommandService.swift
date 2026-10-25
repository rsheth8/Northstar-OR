import Foundation
import Speech
import AVFoundation
import Observation

/// Commands the team can say. Always mirrored by big on-screen buttons as a fallback.
enum VoiceCommand: Equatable {
    case complete, skip, confirm

    /// Maps a transcript to a command. Keep phrases short and distinct for a loud room.
    static func parse(_ transcript: String) -> VoiceCommand? {
        let t = transcript.lowercased().split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
        switch t {
        case "record confirmation": return .complete
        case "defer item": return .skip
        case "acknowledge deferral": return .confirm
        default: break
        }
        return nil
    }
}

/// Short, explicit on-device recognition. Unsupported devices retain touch recording.
@MainActor
@Observable
final class VoiceCommandService {
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    enum State: Equatable { case off, listening, processing, unavailable }
    private(set) var state: State = .off
    var onFinal: ((UUID, String) -> Void)?
    private var generation = UUID()
    private var timeout: Task<Void, Never>?
    private var hasTap = false

    func requestPermissions() async -> Bool {
        let speech = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0 == .authorized) }
        }
        let mic = await AVAudioApplication.requestRecordPermission()
        if !speech || !mic { state = .unavailable }
        return speech && mic
    }

    func start() throws {
        stop()
        guard let recognizer, recognizer.isAvailable, recognizer.supportsOnDeviceRecognition,
              SFSpeechRecognizer.authorizationStatus() == .authorized,
              AVAudioApplication.shared.recordPermission == .granted else {
            state = .unavailable
            throw NSError(domain: "VoiceUnavailable", code: 1)
        }
        let token = UUID()
        generation = token
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = false
        request.requiresOnDeviceRecognition = true
        self.request = request

        let input = audioEngine.inputNode
        input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { buffer, _ in
            request.append(buffer)
        }
        hasTap = true
        audioEngine.prepare()
        try audioEngine.start()

        state = .listening
        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            let transcript = result?.isFinal == true ? result?.bestTranscription.formattedString : nil
            Task { @MainActor [weak self] in
                guard let self, self.generation == token else { return }
                if let transcript {
                    self.stop()
                    self.state = .processing
                    self.onFinal?(token, transcript)
                } else if error != nil {
                    self.stop()
                    self.state = .unavailable
                }
            }
        }
        timeout = Task { [weak self] in
            try? await Task.sleep(for: .seconds(8))
            guard !Task.isCancelled else { return }
            self?.stop()
        }
    }

    func stop() {
        generation = UUID()
        timeout?.cancel()
        timeout = nil
        state = .off
        if audioEngine.isRunning {
            audioEngine.stop()

        }
        if hasTap { audioEngine.inputNode.removeTap(onBus: 0); hasTap = false }
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
    }
}
