import Foundation
import MultipeerConnectivity

/// Experimental nearby adapter. Peer pairing is explicit; display names are not authentication.
@MainActor
final class MultipeerNearbyTransport: NSObject, NearbyTransport {
    private static let service = "nstar-or"
    private let role: DemoPost
    private let peer = MCPeerID(displayName: "OR-" + String(UUID().uuidString.prefix(4)))
    private var session: MCSession?
    private var browser: MCNearbyServiceBrowser?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var discovered: [String: MCPeerID] = [:]
    private var selected: MCPeerID?
    private var invitationHandler: ((Bool, MCSession?) -> Void)?
    private(set) var linkState: NearbyLinkState = .idle
    private(set) var peers: [NearbyPeer] = []
    private(set) var invitation: NearbyPeer?
    private(set) var errorMessage: String?
    var supportsSession: Bool { true }
    var onSnapshot: ((SharedSessionSnapshot) -> Void)?
    var onInvitation: ((CallInvitation) -> Void)?
    var onCallSignal: ((NativeCallSignal) -> Void)?
    var onEnvelope: ((SupportEnvelope) -> Void)?
    var onLinkState: ((NearbyLinkState) -> Void)?
    var onDiscoveryChange: (() -> Void)?

    init(role: DemoPost) { self.role = role; super.init() }
    func start() {
        stop()
        errorMessage = nil
        let session = MCSession(peer: peer, securityIdentity: nil, encryptionPreference: .required)
        self.session = session; session.delegate = self
        let browser = MCNearbyServiceBrowser(peer: peer, serviceType: Self.service)
        let advertiser = MCNearbyServiceAdvertiser(peer: peer,
            discoveryInfo: ["role": role.rawValue, "version": "2"], serviceType: Self.service)
        self.browser = browser; self.advertiser = advertiser
        browser.delegate = self; advertiser.delegate = self
        update(.looking); browser.startBrowsingForPeers(); advertiser.startAdvertisingPeer()
    }
    func stop() {
        invitationHandler?(false, nil); invitationHandler = nil; invitation = nil
        browser?.delegate = nil; browser?.stopBrowsingForPeers(); browser = nil
        advertiser?.delegate = nil; advertiser?.stopAdvertisingPeer(); advertiser = nil
        session?.delegate = nil; session?.disconnect(); session = nil
        discovered = [:]; peers = []; selected = nil
        update(.idle); onDiscoveryChange?()
    }
    func invite(_ peerID: String) throws {
        guard selected == nil, let target = discovered[peerID], let session, let browser else {
            throw NearbyTransportError.invalidPeer
        }
        selected = target
        errorMessage = nil
        browser.invitePeer(target, to: session, withContext: Data(role.rawValue.utf8), timeout: 20)
        onDiscoveryChange?()
    }
    func respondToInvitation(accept: Bool) {
        let callback = invitationHandler; invitationHandler = nil
        if accept, let invitation, let target = discovered[invitation.id], selected == nil, let session {
            selected = target; callback?(true, session)
        } else { callback?(false, nil) }
        invitation = nil; onDiscoveryChange?()
    }
    func send(_ envelope: SupportEnvelope) throws { try sendFrame(.init(envelope: envelope)) }
    func publish(_ snapshot: SharedSessionSnapshot) throws { try sendFrame(.init(snapshot: snapshot)) }
    func sendInvitation(_ invitation: CallInvitation) throws { try sendFrame(.init(invitation: invitation)) }
    func sendCallSignal(_ signal: NativeCallSignal) throws { try sendFrame(.init(signal: signal)) }
    private func sendFrame(_ frame: NearbySessionFrame) throws {
        guard let session, let selected, session.connectedPeers == [selected] else { throw NearbyTransportError.notConnected }
        let data = try JSONEncoder().encode(frame)
        guard data.count <= 512_000 else { throw NearbyTransportError.notConnected }
        try session.send(data, toPeers: [selected], with: .reliable)
    }
    private func update(_ state: NearbyLinkState) { linkState = state; onLinkState?(state) }
    private func failure(_ text: String) {
        errorMessage = text; update(.disconnected); onDiscoveryChange?()
    }
}

extension MultipeerNearbyTransport: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        Task { @MainActor [weak self] in
            guard let self, self.browser === browser, info?["version"] == "2",
                  let otherRole = info?["role"], otherRole != self.role.rawValue,
                  DemoPost(rawValue: otherRole) != nil else { return }
            self.discovered[peerID.displayName] = peerID
            self.peers = self.discovered.values.map { NearbyPeer(id: $0.displayName, name: $0.displayName) }.sorted { $0.id < $1.id }
            self.onDiscoveryChange?()
        }
    }
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task { @MainActor [weak self] in
            guard let self, self.browser === browser else { return }
            self.discovered[peerID.displayName] = nil; self.peers.removeAll { $0.id == peerID.displayName }; self.onDiscoveryChange?()
        }
    }
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        Task { @MainActor [weak self] in
            guard let self, self.browser === browser else { return }
            self.failure("Nearby discovery could not start. Check Local Network access in Settings, then try again.")
        }
    }
}

extension MultipeerNearbyTransport: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        Task { @MainActor [weak self] in
            guard let self, self.advertiser === advertiser, self.selected == nil, self.invitationHandler == nil,
                  let context, let raw = String(data: context, encoding: .utf8), let role = DemoPost(rawValue: raw), role != self.role else {
                invitationHandler(false, nil); return
            }
            self.discovered[peerID.displayName] = peerID
            self.invitation = NearbyPeer(id: peerID.displayName, name: peerID.displayName)
            self.invitationHandler = invitationHandler; self.onDiscoveryChange?()
        }
    }
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        Task { @MainActor [weak self] in
            guard let self, self.advertiser === advertiser else { return }
            self.failure("Nearby advertising could not start. Check Local Network access in Settings, then try again.")
        }
    }
}

extension MultipeerNearbyTransport: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor [weak self] in
            guard let self, self.session === session, self.selected == peerID else { return }
            switch state {
            case .connected: self.update(.connected(peerName: peerID.displayName))
            case .connecting: self.update(.looking)
            case .notConnected: self.selected = nil; self.update(.disconnected)
            @unknown default: self.update(.disconnected)
            }
        }
    }
    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard data.count <= 512_000, let frame = try? JSONDecoder().decode(NearbySessionFrame.self, from: data) else { return }
        Task { @MainActor [weak self] in
            guard let self, self.session === session, self.selected == peerID,
                  session.connectedPeers.contains(peerID) else { return }
            if let value = frame.snapshot { self.onSnapshot?(value) }
            if let value = frame.envelope { self.onEnvelope?(value) }
            if let value = frame.invitation { self.onInvitation?(value) }
            if let value = frame.signal { self.onCallSignal?(value) }
        }
    }
    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) { stream.close() }
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) { progress.cancel() }
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
