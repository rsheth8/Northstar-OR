import SwiftUI
@preconcurrency import WebRTC

/// Renders an existing local or remote track; no second capture session.
/// WebRTC stays within the service adapter rather than the feature view.
struct NearbyCallCameraPreview: UIViewRepresentable {
    @ObservedObject var call: NearbyCallController
    var local = false

    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context: Context) -> RTCMTLVideoView {
        let view = RTCMTLVideoView(frame: .zero)
        view.videoContentMode = .scaleAspectFit
        return view
    }
    func updateUIView(_ view: RTCMTLVideoView, context: Context) {
        context.coordinator.attach(local ? call.localVideoTrack : (call.remoteCameraEnabled ? call.remoteVideoTrack : nil), to: view)
    }
    static func dismantleUIView(_ view: RTCMTLVideoView, coordinator: Coordinator) {
        coordinator.attach(nil, to: view)
    }
    final class Coordinator {
        private var track: RTCVideoTrack?
        func attach(_ next: RTCVideoTrack?, to view: RTCMTLVideoView) {
            guard track !== next else { return }
            track?.remove(view)
            track = next
            next?.add(view)
        }
    }
}
