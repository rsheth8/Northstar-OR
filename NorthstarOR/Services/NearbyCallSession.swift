import AVFoundation
import Foundation
@preconcurrency import WebRTC

/// Media controller with scoped native signaling, plus the legacy browser-call
/// adapter. AppModel remains the authority for invitations and retained support.
@MainActor
final class NearbyCallController: ObservableObject, NearbyTransport {
    @Published private(set) var status = "Call ended"
    @Published private(set) var muted = false
    @Published private(set) var cameraStatus = "Camera off"
    @Published private(set) var remoteCameraEnabled = true
    @Published private(set) var remoteCameraStatus = "Waiting for peer camera"
    @Published private(set) var cameraEnabled = false
    @Published private(set) var cameraFacing = "back"
    @Published private(set) var canSwitchCamera = false
    @Published private(set) var localVideoTrack: RTCVideoTrack?
    @Published private(set) var remoteVideoTrack: RTCVideoTrack?
    private(set) var linkState: NearbyLinkState = .idle
    var onEnvelope: ((SupportEnvelope) -> Void)?
    var onLinkState: ((NearbyLinkState) -> Void)?
    private var engine: NearbyCallEngine?
    private var generation = UUID()
    private let signalingURL: String?
    private let role: DemoPost
    private let sendSignal: ((String) -> Void)?
    private var pendingSignals: [String] = []

    init(signalingURL: String) {
        self.signalingURL = signalingURL
        role = .room
        sendSignal = nil
    }
    init(role: DemoPost, sendSignal: @escaping (String) -> Void) {
        signalingURL = nil
        self.role = role
        self.sendSignal = sendSignal
    }
    func receiveSignal(_ text: String) {
        guard text.utf8.count <= 512 * 1024 else { return }
        if let engine { engine.receiveSignal(text) }
        else if pendingSignals.count < 128 { pendingSignals.append(text) }
    }

    static func requestMicrophoneAccess() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .audio)
    }

    func start() {
        stop()
        let url = signalingURL.flatMap(URL.init(string:))
        if sendSignal == nil {
            guard let url, ["ws", "wss"].contains(url.scheme), url.host != nil else {
                fail("Enter a server address such as ws://192.168.1.20:8080"); return
            }
        }
        let run = generation
        status = "Allow microphone access"
        setLink(.looking)
        Task {
            let microphone = await Self.requestMicrophoneAccess()
            guard run == generation else { return }
            guard microphone else { fail("Microphone access is off. Enable it in Settings, then retry."); return }
            #if targetEnvironment(simulator)
            let camera = false
            cameraStatus = "Camera unavailable in the simulator"
            #else
            let camera = await AVCaptureDevice.requestAccess(for: .video)
            guard run == generation else { return }
            cameraStatus = camera ? "Starting your camera" : "Camera access is off · audio only"
            #endif
            let engine = NearbyCallEngine()
            self.engine = engine
            engine.onStatus = { [weak self] status in
                guard let self, self.generation == run else { return }
                self.status = status
                if status == "In call" { self.setLink(.connected(peerName: self.role == .room ? "Representative" : "Room iPad")) }
                else if status != "Connecting" { self.setLink(.disconnected) }
            }
            engine.onEnvelope = { [weak self] envelope in
                guard let self, self.generation == run else { return }
                self.onEnvelope?(envelope)
            }
            engine.onCameraState = { [weak self] state in
                guard let self, self.generation == run else { return }
                self.cameraStatus = state
            }
            engine.onRemoteCameraState = { [weak self] enabled in
                guard let self, self.generation == run else { return }
                self.remoteCameraEnabled = enabled
                self.remoteCameraStatus = enabled ? "Peer camera on" : "Peer camera off · audio can continue"
            }
            engine.onLocalVideoTrack = { [weak self] track in
                guard let self, self.generation == run else { return }
                self.localVideoTrack = track
            }
            engine.onRemoteVideoTrack = { [weak self] track in
                guard let self, self.generation == run else { return }
                self.remoteVideoTrack = track
            }
            engine.onCameraControl = { [weak self] enabled, facing, canSwitch in
                guard let self, self.generation == run else { return }
                self.cameraEnabled = enabled
                self.cameraFacing = facing
                self.canSwitchCamera = canSwitch
            }
            engine.start(url: url, camera: camera, role: role, sendSignal: sendSignal)
            engine.setMuted(muted)
            let queued = pendingSignals
            pendingSignals.removeAll()
            for signal in queued { engine.receiveSignal(signal) }
        }
    }

    func stop() {
        generation = UUID()
        engine?.stop(); engine = nil; localVideoTrack = nil; remoteVideoTrack = nil
        pendingSignals.removeAll()
        status = "Call ended"; muted = false; cameraStatus = "Camera off"
        cameraEnabled = false; cameraFacing = "back"; canSwitchCamera = false
        remoteCameraEnabled = true; remoteCameraStatus = "Waiting for peer camera"
        setLink(.idle)
    }
    func setMuted(_ value: Bool) { muted = value; engine?.setMuted(value) }
    func setCameraEnabled(_ value: Bool) { engine?.setCameraEnabled(value) }
    func switchCamera() { engine?.switchCamera() }
    func send(_ envelope: SupportEnvelope) throws {
        guard case .connected = linkState, let engine else { throw NearbyTransportError.notConnected }
        try engine.send(envelope)
    }
    private func setLink(_ state: NearbyLinkState) { linkState = state; onLinkState?(state) }
    private func fail(_ message: String) { status = message; setLink(.disconnected) }
}

/// WebRTC delegates arrive on worker queues. Every callback enters the main
/// actor and checks the exact peer/socket so ended calls cannot affect a retry.
@MainActor
private final class NearbyCallEngine: NSObject, URLSessionWebSocketDelegate, RTCPeerConnectionDelegate, RTCDataChannelDelegate {
    var onStatus: ((String) -> Void)?
    var onEnvelope: ((SupportEnvelope) -> Void)?
    var onCameraState: ((String) -> Void)?
    var onRemoteCameraState: ((Bool) -> Void)?
    var onLocalVideoTrack: ((RTCVideoTrack?) -> Void)?
    var onRemoteVideoTrack: ((RTCVideoTrack?) -> Void)?
    var onCameraControl: ((Bool, String, Bool) -> Void)?
    private static let factory: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        return RTCPeerConnectionFactory()
    }()
    private var connection: RTCPeerConnection?
    private var dataChannel: RTCDataChannel?
    private var socket: URLSessionWebSocketTask?
    private var session: URLSession?
    private var audioTrack: RTCAudioTrack?
    private var capturer: RTCCameraVideoCapturer?
    private var videoTrack: RTCVideoTrack?
    // RTCVideoCapturer.delegate is weak; retain the actual delegate wrapper.
    private var videoSource: RTCVideoSource?
    private var cameraFacing: AVCaptureDevice.Position = .back
    private var cameraEnabled = false
    private var cameraGeneration = UUID()
    private var role: DemoPost = .room
    private var externalSignal: ((String) -> Void)?
    private var offered = false
    private var remoteDescriptionSet = false
    private var pendingCandidates: [RTCIceCandidate] = []
    private var connected = false
    private var timeout: Task<Void, Never>?

    func start(url: URL?, camera: Bool, role: DemoPost, sendSignal: ((String) -> Void)?) {
        self.role = role
        externalSignal = sendSignal
        do {
            let audio = RTCAudioSession.sharedInstance()
            audio.lockForConfiguration()
            defer { audio.unlockForConfiguration() }
            try audio.setCategory(AVAudioSession.Category.playAndRecord, with: [.defaultToSpeaker, .allowBluetooth])
            try audio.setMode(.voiceChat)
            try audio.setPreferredIOBufferDuration(0.02)
            try audio.setActive(true)
        } catch { fail("Audio unavailable. End the call and retry."); return }
        let config = RTCConfiguration()
        config.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        config.sdpSemantics = .unifiedPlan
        config.bundlePolicy = .maxBundle
        config.rtcpMuxPolicy = .require
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        guard let peer = Self.factory.peerConnection(with: config, constraints: constraints, delegate: self) else {
            fail("Call failed. End the call and retry."); return
        }
        connection = peer
        let audio = Self.factory.audioTrack(with: Self.factory.audioSource(with: constraints), trackId: "audio0")
        audioTrack = audio
        peer.add(audio, streamIds: ["northstar"])
        if camera {
            let source = Self.factory.videoSource()
            videoSource = source
            let capture = RTCCameraVideoCapturer(delegate: source)
            capturer = capture
            let video = Self.factory.videoTrack(with: source, trackId: "video0")
            videoTrack = video
            peer.add(video, streamIds: ["northstar"])
            cameraEnabled = true
            startCamera(capture, position: role == .rep ? .front : .back)
        } else {
            let receiveVideo = RTCRtpTransceiverInit()
            receiveVideo.direction = .recvOnly
            peer.addTransceiver(of: .video, init: receiveVideo)
        }
        if sendSignal == nil {
            let channelConfig = RTCDataChannelConfiguration()
            channelConfig.isOrdered = true
            dataChannel = peer.dataChannel(forLabel: "northstar", configuration: channelConfig)
            dataChannel?.delegate = self
        }
        onStatus?("Connecting")
        if sendSignal != nil {
            if role == .rep { signal(["type": "ready"]) }
        } else if let url {
            let urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
            session = urlSession
            var address = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            address.queryItems = (address.queryItems ?? []).filter { $0.name != "role" } + [URLQueryItem(name: "role", value: "room")]
            let task = urlSession.webSocketTask(with: address.url!)
            socket = task
            task.resume()
        }
        timeout = Task { [weak self] in
            try? await Task.sleep(for: .seconds(30))
            guard !Task.isCancelled, let self else { return }
            guard !(connected && (externalSignal != nil || dataChannel?.readyState == .open)) else { return }
            fail("Call timed out. Check both devices’ connection, then retry.")
        }
    }
    func stop() {
        timeout?.cancel(); timeout = nil
        cameraGeneration = UUID()
        cameraEnabled = false
        offered = false
        externalSignal = nil
        onRemoteVideoTrack?(nil)
        let camera = capturer; capturer = nil; camera?.stopCapture()
        videoTrack = nil; videoSource = nil; onLocalVideoTrack?(nil)
        let channel = dataChannel; dataChannel = nil; channel?.close()
        let peer = connection; connection = nil; peer?.close()
        let task = socket; socket = nil; task?.cancel(with: .goingAway, reason: nil)
        session?.invalidateAndCancel(); session = nil
        audioTrack = nil; connected = false; remoteDescriptionSet = false
        pendingCandidates.removeAll()
        let audio = RTCAudioSession.sharedInstance()
        audio.lockForConfiguration()
        try? audio.setActive(false)
        audio.unlockForConfiguration()
    }
    func setMuted(_ value: Bool) { audioTrack?.isEnabled = !value }
    func setCameraEnabled(_ enabled: Bool) {
        guard let camera = capturer, let track = videoTrack else {
            reportCamera(enabled: false, status: "Camera unavailable · audio only")
            return
        }
        cameraGeneration = UUID()
        cameraEnabled = enabled
        track.isEnabled = enabled
        if enabled {
            startCamera(camera, position: cameraFacing)
        } else {
            camera.stopCapture()
            onLocalVideoTrack?(nil)
            reportCamera(enabled: false, status: "Camera off · microphone can stay on")
        }
    }
    func switchCamera() {
        let next: AVCaptureDevice.Position = cameraFacing == .back ? .front : .back
        guard cameraEnabled, let camera = capturer, let track = videoTrack, track.isEnabled,
              RTCCameraVideoCapturer.captureDevices().contains(where: { $0.position == next }) else {
            reportCamera(enabled: cameraEnabled, status: cameraEnabled ? "Only one camera is available" : "Camera off · microphone can stay on")
            return
        }
        cameraFacing = next
        startCamera(camera, position: next)
    }
    func send(_ envelope: SupportEnvelope) throws {
        guard let channel = dataChannel, channel.readyState == .open else { throw NearbyTransportError.notConnected }
        let data = try JSONEncoder().encode(envelope)
        guard data.count <= 512 * 1024, channel.sendData(RTCDataBuffer(data: data, isBinary: false)) else {
            throw NearbyTransportError.notConnected
        }
    }
    private func fail(_ message: String) { stop(); onStatus?(message) }
    private func updateConnected() {
        if connected, externalSignal != nil || dataChannel?.readyState == .open { timeout?.cancel(); onStatus?("In call") }
    }
    private func startCamera(_ camera: RTCCameraVideoCapturer, position: AVCaptureDevice.Position) {
        cameraGeneration = UUID()
        let run = cameraGeneration
        let devices = RTCCameraVideoCapturer.captureDevices()
        guard let device = devices.first(where: { $0.position == position }) ?? devices.first,
              let format = RTCCameraVideoCapturer.supportedFormats(for: device).min(by: {
                  let a = CMVideoFormatDescriptionGetDimensions($0.formatDescription)
                  let b = CMVideoFormatDescriptionGetDimensions($1.formatDescription)
                  return abs(Int(a.width) - 640) + abs(Int(a.height) - 480) < abs(Int(b.width) - 640) + abs(Int(b.height) - 480)
              }) else {
            cameraEnabled = false
            videoTrack?.isEnabled = false
            onLocalVideoTrack?(nil)
            reportCamera(enabled: false, status: "Camera unavailable · audio only")
            return
        }
        cameraFacing = device.position
        let fps = max(1, min(24, Int(format.videoSupportedFrameRateRanges.map(\.maxFrameRate).max() ?? 24)))
        camera.startCapture(with: device, format: format, fps: fps) { [weak self] error in
            DispatchQueue.main.async {
                guard let self, self.capturer === camera, self.cameraGeneration == run, self.cameraEnabled else { return }
                if error != nil {
                    self.cameraEnabled = false
                    self.videoTrack?.isEnabled = false
                    self.onLocalVideoTrack?(nil)
                    self.reportCamera(enabled: false, status: "Camera unavailable · audio only")
                } else {
                    let front = device.position == .front
                    self.onLocalVideoTrack?(self.videoTrack)
                    self.reportCamera(enabled: true, status: front ? "Front camera on · video is not saved" : "Room camera on · video is not saved")
                }
            }
        }
    }
    private func reportCamera(enabled: Bool, status: String) {
        onCameraState?(status)
        let facing = cameraFacing == .front ? "front" : "back"
        let canSwitch = Set(RTCCameraVideoCapturer.captureDevices().map(\.position)).count > 1
        onCameraControl?(enabled, facing, canSwitch)
        signal(["type": "camera", "enabled": enabled, "facing": facing])
    }
    private func makeOffer(_ peer: RTCPeerConnection) {
        peer.offer(for: RTCMediaConstraints(mandatoryConstraints: ["OfferToReceiveAudio": "true", "OfferToReceiveVideo": "true"], optionalConstraints: nil)) { [weak self] sdp, error in
            DispatchQueue.main.async {
                guard let self, self.connection === peer else { return }
                guard let sdp, error == nil else { self.fail("Could not prepare the call. Retry."); return }
                peer.setLocalDescription(sdp) { [weak self] error in
                    DispatchQueue.main.async {
                        guard let self, self.connection === peer else { return }
                        guard error == nil else { self.fail("Could not prepare the call. Retry."); return }
                        self.signal(["type": "offer", "sdp": sdp.sdp])
                        self.signal(["type": "camera", "enabled": self.cameraEnabled])
                    }
                }
            }
        }
    }
    private func receive(_ task: URLSessionWebSocketTask) {
        task.receive { [weak self] result in
            DispatchQueue.main.async {
                guard let self, self.socket === task else { return }
                switch result {
                case .success(let message):
                    if case .string(let text) = message { self.handleSignal(text) }
                    if self.socket === task { self.receive(task) }
                case .failure: self.fail("Signaling disconnected. Check the laptop server and retry.")
                }
            }
        }
    }
    func receiveSignal(_ text: String) { handleSignal(text) }
    private func handleSignal(_ text: String) {
        guard let data = text.data(using: .utf8), let message = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = message["type"] as? String, let peer = connection else { return }
        switch type {
        case "ready":
            guard role == .room, !offered else { return }
            offered = true
            makeOffer(peer)
        case "offer":
            guard role == .rep, let sdp = message["sdp"] as? String else { return }
            peer.setRemoteDescription(RTCSessionDescription(type: .offer, sdp: sdp)) { [weak self] error in
                DispatchQueue.main.async {
                    guard let self, self.connection === peer else { return }
                    guard error == nil else { self.fail("Could not receive the room call. Retry."); return }
                    self.remoteDescriptionSet = true
                    self.flushCandidates(peer)
                    peer.answer(for: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)) { [weak self] answer, error in
                        DispatchQueue.main.async {
                            guard let self, self.connection === peer else { return }
                            guard let answer, error == nil else { self.fail("Could not answer the call. Retry."); return }
                            peer.setLocalDescription(answer) { [weak self] error in
                                DispatchQueue.main.async {
                                    guard let self, self.connection === peer else { return }
                                    guard error == nil else { self.fail("Could not answer the call. Retry."); return }
                                    self.signal(["type": "answer", "sdp": answer.sdp])
                                    self.signal(["type": "camera", "enabled": self.cameraEnabled])
                                }
                            }
                        }
                    }
                }
            }
        case "camera":
            guard let enabled = message["enabled"] as? Bool else { return }
            onRemoteCameraState?(enabled)
        case "end": fail("Call ended. Your saved messages are kept.")
        case "answer":
            guard role == .room else { return }
            guard let sdp = message["sdp"] as? String else { return }
            peer.setRemoteDescription(RTCSessionDescription(type: .answer, sdp: sdp)) { [weak self] error in
                DispatchQueue.main.async {
                    guard let self, self.connection === peer else { return }
                    guard error == nil else { self.fail("The rep could not join. Restart the call."); return }
                    self.remoteDescriptionSet = true
                    self.flushCandidates(peer)
                }
            }
        case "candidate":
            guard let sdp = message["candidate"] as? String else { return }
            let candidate = RTCIceCandidate(sdp: sdp, sdpMLineIndex: (message["sdpMLineIndex"] as? NSNumber)?.int32Value ?? 0, sdpMid: message["sdpMid"] as? String)
            if remoteDescriptionSet { peer.add(candidate, completionHandler: { _ in }) } else if pendingCandidates.count < 256 { pendingCandidates.append(candidate) }
        case "peer-left": fail("Rep disconnected. Open the rep page and restart the call.")
        case "busy": fail("Another room is connected. End that call first.")
        default: break
        }
    }
    private func flushCandidates(_ peer: RTCPeerConnection) {
        for candidate in pendingCandidates { peer.add(candidate, completionHandler: { _ in }) }
        pendingCandidates.removeAll()
    }
    private func signal(_ object: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: object), let text = String(data: data, encoding: .utf8) else { return }
        if let externalSignal { externalSignal(text); return }
        guard let task = socket else { return }
        task.send(.string(text)) { [weak self] error in
            if error != nil { DispatchQueue.main.async { if self?.socket === task { self?.fail("Could not reach the signaling server. Retry.") } } }
        }
    }
    nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.socket === webSocketTask, let peer = self.connection else { return }
            self.receive(webSocketTask); self.makeOffer(peer)
        }
    }
    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self, self.socket === task else { return }
            self.fail("Cannot reach the laptop server. Check the server address, Wi-Fi and Northstar’s Local Network permission. " + error.localizedDescription)
        }
    }
    nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        DispatchQueue.main.async { [weak self] in if self?.socket === webSocketTask { self?.fail("Signaling disconnected. Restart the call.") } }
    }
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {}
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        publishRemoteVideo(stream.videoTracks.first, peer: peerConnection)
    }
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didStartReceivingOn transceiver: RTCRtpTransceiver) {
        publishRemoteVideo(transceiver.receiver.track as? RTCVideoTrack, peer: peerConnection)
    }
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didAdd rtpReceiver: RTCRtpReceiver, streams: [RTCMediaStream]) {
        publishRemoteVideo(rtpReceiver.track as? RTCVideoTrack, peer: peerConnection)
    }
    nonisolated private func publishRemoteVideo(_ track: RTCVideoTrack?, peer: RTCPeerConnection) {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.connection === peer, let track else { return }
            self.onRemoteVideoTrack?(track)
        }
    }
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {}
    nonisolated func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {}
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {}
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {}
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.connection === peerConnection else { return }
            self.signal(["type": "candidate", "candidate": candidate.sdp, "sdpMid": candidate.sdpMid ?? "", "sdpMLineIndex": candidate.sdpMLineIndex])
        }
    }
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCPeerConnectionState) {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.connection === peerConnection else { return }
            switch newState {
            case .connected: self.connected = true; self.updateConnected()
            case .disconnected, .failed, .closed: self.fail("Call disconnected. Your saved questions are kept. Restart to reconnect.")
            default: break
            }
        }
    }
    nonisolated func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.dataChannel === dataChannel else { return }
            if dataChannel.readyState == .closed { self.fail("Call ended. Your saved questions are kept.") }
            else { self.updateConnected() }
        }
    }
    nonisolated func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        guard buffer.data.count <= 512 * 1024, let envelope = try? JSONDecoder().decode(SupportEnvelope.self, from: buffer.data) else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self, self.dataChannel === dataChannel else { return }
            self.onEnvelope?(envelope)
        }
    }
}
