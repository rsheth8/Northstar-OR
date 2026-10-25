import Foundation

/// Read-only projection of the room record; this never grants recording authority.
struct SharedSessionSnapshot: Codable {
    let origin: SupportOrigin
    let context: SupportContextSnapshot
    let recordingSummary: String
    let saved: Bool
    let questions: [SupportQuestion]
}

private struct SharedSessionFrame: Codable {
    let type: String
    var snapshot: SharedSessionSnapshot? = nil
    var envelope: SupportEnvelope? = nil
}

/// Same-Wi-Fi data channel, independent of the WebRTC microphone/camera lifetime.
@MainActor
final class SharedSessionTransport: NearbyTransport {
    private(set) var linkState: NearbyLinkState = .idle
    private(set) var errorMessage: String?
    var onEnvelope: ((SupportEnvelope) -> Void)?
    var onLinkState: ((NearbyLinkState) -> Void)?
    var onDiscoveryChange: (() -> Void)?
    var onRefresh: (() -> Void)?
    private let server: String
    private var session: URLSession?
    private var socket: URLSessionWebSocketTask?
    private var reader: Task<Void, Never>?

    init(server: String) { self.server = server }
    func start() {
        stop()
        guard var address = URLComponents(string: server),
              ["ws", "wss"].contains(address.scheme), address.host != nil else {
            fail("Enter the laptop server address, such as ws://192.168.1.20:8080"); return
        }
        address.path = "/session"
        address.queryItems = [URLQueryItem(name: "role", value: "room")]
        guard let url = address.url else { fail("The server address is invalid."); return }
        errorMessage = nil
        let session = URLSession(configuration: .default)
        self.session = session
        let socket = session.webSocketTask(with: url)
        socket.maximumMessageSize = 512 * 1024
        self.socket = socket
        setLink(.looking)
        socket.resume()
        reader = Task { [weak self] in
            do {
                while !Task.isCancelled {
                    let message = try await socket.receive()
                    guard let self, self.socket === socket else { return }
                    let data: Data
                    switch message {
                    case .data(let bytes): data = bytes
                    case .string(let text): data = Data(text.utf8)
                    @unknown default: continue
                    }
                    let frame = try JSONDecoder().decode(SharedSessionFrame.self, from: data)
                    switch frame.type {
                    case "peer-joined":
                        self.setLink(.connected(peerName: "Rep laptop · session"))
                        self.onRefresh?()
                    case "snapshot-request": self.onRefresh?()
                    case "support-envelope":
                        if let envelope = frame.envelope { self.onEnvelope?(envelope) }
                    case "peer-left": self.setLink(.disconnected)
                    case "busy": self.fail("Another room is sharing. Stop that session first."); return
                    default: break
                    }
                }
            } catch {
                guard let self, self.socket === socket, !Task.isCancelled else { return }
                self.fail("Session disconnected. Check Wi-Fi and the laptop server, then share again.")
            }
        }
    }
    func stop() {
        reader?.cancel(); reader = nil
        let old = socket; socket = nil
        old?.cancel(with: .goingAway, reason: nil)
        session?.invalidateAndCancel(); session = nil
        setLink(.idle)
    }
    func send(_ envelope: SupportEnvelope) throws {
        guard case .connected = linkState else { throw NearbyTransportError.notConnected }
        try sendFrame(.init(type: "support-envelope", envelope: envelope))
    }
    func publish(_ snapshot: SharedSessionSnapshot) throws {
        guard case .connected = linkState else { return }
        try sendFrame(.init(type: "session-snapshot", snapshot: snapshot))
    }
    private func sendFrame(_ frame: SharedSessionFrame) throws {
        guard let socket else { throw NearbyTransportError.notConnected }
        let data = try JSONEncoder().encode(frame)
        guard data.count <= 512 * 1024 else {
            fail("Session is too large to share. The saved room record remains available.")
            throw NearbyTransportError.notConnected
        }
        socket.send(.string(String(decoding: data, as: UTF8.self))) { [weak self] error in
            guard error != nil else { return }
            Task { @MainActor in
                guard let self, self.socket === socket else { return }
                self.fail("Session send failed. Saved questions remain available to retry.")
            }
        }
    }
    private func setLink(_ value: NearbyLinkState) { linkState = value; onLinkState?(value); onDiscoveryChange?() }
    private func fail(_ message: String) { stop(); errorMessage = message; setLink(.disconnected) }
}
