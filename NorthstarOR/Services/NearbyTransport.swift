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
    func start()
    func stop()
    func send(_ envelope: SupportEnvelope) throws
    func invite(_ peerID: String) throws
    func respondToInvitation(accept: Bool)
}

extension NearbyTransport {
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
