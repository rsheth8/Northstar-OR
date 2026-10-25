import SwiftUI
@preconcurrency import WebRTC

/// Renders the same track sent to the laptop; no second capture session.
/// WebRTC stays within the service adapter rather than the feature view.
struct NearbyCallCameraPreview: UIViewRepresentable {
    @ObservedObject var call: NearbyCallController

    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context: Context) -> RTCMTLVideoView {
        let view = RTCMTLVideoView(frame: .zero)
        view.videoContentMode = .scaleAspectFit
        return view
    }
    func updateUIView(_ view: RTCMTLVideoView, context: Context) {
        context.coordinator.attach(call.remoteVideoTrack ?? call.localVideoTrack, to: view)
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
