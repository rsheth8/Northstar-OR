import Foundation

enum DemoPost: String, CaseIterable { case room, rep }
enum NearbyLinkState: Equatable {
    case idle, looking, connected(peerName: String), disconnected
    var label: String {
        switch self {
        case .idle: "On this device"
        case .looking: "Nearby · looking"
        case .connected(let name): "Nearby · \(name)"
        case .disconnected: "Nearby · disconnected"
        }
    }
}
enum NearbyTransportError: Error { case notConnected, invalidPeer }
struct NearbyPeer: Identifiable, Equatable {
    let id: String
    let name: String
}

@MainActor
protocol NearbyTransport: AnyObject {
    var linkState: NearbyLinkState { get }
    var peers: [NearbyPeer] { get }
    var invitation: NearbyPeer? { get }
    var errorMessage: String? { get }
    var onEnvelope: ((SupportEnvelope) -> Void)? { get set }
    var onLinkState: ((NearbyLinkState) -> Void)? { get set }
    var onDiscoveryChange: (() -> Void)? { get set }
    var supportsSession: Bool { get }
    var onSnapshot: ((SharedSessionSnapshot) -> Void)? { get set }
    var onInvitation: ((CallInvitation) -> Void)? { get set }
    var onCallSignal: ((NativeCallSignal) -> Void)? { get set }
    func publish(_ snapshot: SharedSessionSnapshot) throws
    func sendInvitation(_ invitation: CallInvitation) throws
    func sendCallSignal(_ signal: NativeCallSignal) throws
    func start()
    func stop()
    func send(_ envelope: SupportEnvelope) throws
    func invite(_ peerID: String) throws
    func respondToInvitation(accept: Bool)
}

extension NearbyTransport {
    var supportsSession: Bool { false }
    var onSnapshot: ((SharedSessionSnapshot) -> Void)? { get { nil } set {} }
    var onInvitation: ((CallInvitation) -> Void)? { get { nil } set {} }
    var onCallSignal: ((NativeCallSignal) -> Void)? { get { nil } set {} }
    func publish(_ snapshot: SharedSessionSnapshot) throws { throw NearbyTransportError.notConnected }
    func sendInvitation(_ invitation: CallInvitation) throws { throw NearbyTransportError.notConnected }
    func sendCallSignal(_ signal: NativeCallSignal) throws { throw NearbyTransportError.notConnected }
    var peers: [NearbyPeer] { [] }
    var invitation: NearbyPeer? { nil }
    var errorMessage: String? { nil }
    var onDiscoveryChange: (() -> Void)? { get { nil } set {} }
    func invite(_ peerID: String) throws { throw NearbyTransportError.invalidPeer }
    func respondToInvitation(accept: Bool) {}
}

@MainActor
final class IdleNearbyTransport: NearbyTransport {
    var linkState: NearbyLinkState { .idle }
    var onEnvelope: ((SupportEnvelope) -> Void)?
    var onLinkState: ((NearbyLinkState) -> Void)?
    func start() {}
    func stop() {}
    func send(_ envelope: SupportEnvelope) throws { throw NearbyTransportError.notConnected }
}

extension SupportDelivery {
    var label: String {
        switch self {
        case .onThisDevice: "On this device"
        case .waitingForPeer: "Waiting for recipient receipt"
        case .receivedByPeer: "Received by recipient"
        case .failed: "Not sent. This message is kept."
        }
    }
}

struct NativeCallSignal: Codable {
    let callID: String
    let origin: SupportOrigin
    let payload: String
}

struct NearbySessionFrame: Codable {
    var snapshot: SharedSessionSnapshot? = nil
    var envelope: SupportEnvelope? = nil
    var invitation: CallInvitation? = nil
    var signal: NativeCallSignal? = nil
}
