import SwiftUI

/// Contextual entry point shared by the question composer and both workspaces.
struct WorkspaceCallAction: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        VStack(alignment: .leading, spacing: Northstar.Space.s2) {
            if model.callInvitation?.state == .requested {
                if model.callInvitation?.from.rawValue == model.demoPost.rawValue {
                    Text("Waiting for call acceptance").font(Northstar.Fonts.bodyStrong)
                    Button("Cancel call request") { model.cancelInvitation() }
                        .buttonStyle(NorthstarSecondaryButtonStyle())
                } else {
                    Text("Incoming call").font(Northstar.Fonts.bodyStrong)
                    Button("Accept call") { model.acceptInvitation() }
                        .buttonStyle(NorthstarPrimaryButtonStyle(tone: .standard))
                        .disabled(model.supportRecordingEnded)
                    Button("Decline call") { model.declineInvitation() }
                        .buttonStyle(NorthstarSecondaryButtonStyle())
                }
            } else if model.callInvitation?.state == .accepted {
                Label("Call open alongside workspace", systemImage: "video")
                    .font(Northstar.Fonts.bodyStrong)
            } else {
                Button { model.requestCall() } label: { Label("Request call", systemImage: "video") }
                    .buttonStyle(NorthstarPrimaryButtonStyle(tone: .standard))
                    .disabled(!connected || model.supportRecordingEnded || (model.demoPost == .rep && !model.remoteSessionCurrent))
                    .accessibilityIdentifier("request-call")
                Text(connected ? "The other device accepts before audio and video start." : "Connect devices to request a call. You can keep writing your question.")
                    .font(Northstar.Fonts.supporting)
                if let state = model.callInvitation?.state {
                    Text(state == .declined ? "Call declined" : state == .expired ? "Call request expired" : "Call request canceled")
                        .font(Northstar.Fonts.supporting)
                }
            }
            if let error = model.nearbyError {
                Label(error, systemImage: "exclamationmark.triangle").font(Northstar.Fonts.supporting)
                    .foregroundStyle(Northstar.Palette.alert)
            }
        }
    }
    private var connected: Bool { if case .connected = model.linkState { return true }; return false }
}

/// Lives outside tab navigation and sheets: minimizing never stops media.
struct WorkspaceCallPanel: View {
    @Environment(AppModel.self) private var model
    var compact = false
    var body: some View {
        VStack(alignment: .leading, spacing: Northstar.Space.s3) {
                Text(model.demoPost == .room ? "Representative call" : "Room call").font(Northstar.Fonts.bodyStrong)
                if let call = model.nearbyCall, model.callInvitation?.state == .accepted {
                    WorkspaceCallMedia(call: call, compact: compact, end: model.endRepCall)
                } else { ScrollView { WorkspaceCallAction() } }
        }.padding(Northstar.Space.s3)
        .background(Northstar.Palette.bgBase)
        .accessibilityIdentifier("workspace-call-panel")
    }
}

struct WorkspaceCallMedia: View {
    @Environment(AppModel.self) private var model
    @ObservedObject var call: NearbyCallController
    let compact: Bool
    let end: () -> Void
    @State private var videoVisible = true
    var body: some View {
        VStack(alignment: .leading, spacing: Northstar.Space.s3) {
            ScrollView {
            VStack(alignment: .leading, spacing: Northstar.Space.s3) {
            NorthstarStatusLabel(call.status, tone: .info)
            Button(videoVisible ? "Minimize video" : "Show video") { videoVisible.toggle() }
                .frame(minHeight: 44)
                .accessibilityIdentifier("call-video-size")
            if videoVisible {
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Northstar.Palette.bgSunken
                    if call.remoteCameraEnabled, call.remoteVideoTrack != nil {
                        NearbyCallCameraPreview(call: call)
                    } else {
                        Label(call.remoteCameraEnabled ? "Waiting for video" : "Peer camera off", systemImage: "video.slash")
                            .font(Northstar.Fonts.supporting)
                    }
                }
                .accessibilityLabel(model.demoPost == .room ? "Representative video" : "Room video")
                if call.localVideoTrack != nil, call.cameraEnabled {
                    NearbyCallCameraPreview(call: call, local: true)
                        .frame(width: 88, height: 66)
                        .background(Northstar.Palette.bgRaised)
                        .clipShape(RoundedRectangle(cornerRadius: Northstar.Radius.sm))
                        .padding(Northstar.Space.s2)
                        .accessibilityLabel("Your shared camera preview")
                }
            }
            .frame(height: compact ? 120 : 220)
            .clipShape(RoundedRectangle(cornerRadius: Northstar.Radius.sm))
            }
            Text(call.cameraStatus).font(Northstar.Fonts.supporting)
            Text(call.status != "In call" ? "Microphone not connected" : call.muted ? "Your microphone is muted" : "Your microphone is on")
                .font(Northstar.Fonts.supporting)
            if call.canSwitchCamera {
                Button("Flip camera") { call.switchCamera() }
                    .buttonStyle(NorthstarSecondaryButtonStyle())
                    .disabled(!call.cameraEnabled || call.status != "In call")
                    .accessibilityIdentifier("call-camera-flip")
            }
            Text("Video is live and is not saved. Messages and checklist stay available.")
                .font(Northstar.Fonts.supporting)
            }
            }
            ViewThatFits(in: .horizontal) {
                HStack { mute; camera }
                VStack { mute; camera }
            }
            Button("End call", action: end).buttonStyle(NorthstarSecondaryButtonStyle())
                .accessibilityIdentifier("call-end")
        }
    }
    private var mute: some View {
        Button { call.setMuted(!call.muted) } label: {
            Label(call.muted ? "Unmute" : "Mute", systemImage: call.muted ? "mic.slash" : "mic")
        }.buttonStyle(NorthstarSecondaryButtonStyle()).disabled(call.status != "In call")
            .accessibilityIdentifier("call-mute")
    }
    private var camera: some View {
        Button { call.setCameraEnabled(!call.cameraEnabled) } label: {
            Label(call.cameraEnabled ? "Camera off" : "Camera on", systemImage: call.cameraEnabled ? "video" : "video.slash")
        }.buttonStyle(NorthstarSecondaryButtonStyle())
            .disabled(call.status != "In call" || (!call.cameraEnabled && call.localVideoTrack == nil && !call.canSwitchCamera))
            .accessibilityIdentifier("call-camera-enabled")
    }
}

/// On wide windows the dock reserves space. A user can float and move the tile;
/// narrow/enlarged-text windows reserve a compact bottom panel instead.
struct CallWorkspace<Content: View>: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var floating = false
    @State private var expanded = false
    @State private var offset: CGSize = .zero
    @GestureState private var drag: CGSize = .zero
    @ViewBuilder let content: () -> Content
    private var visible: Bool { model.callInvitation?.state == .requested || model.callInvitation?.state == .accepted }
    var body: some View {
        GeometryReader { geometry in
            let wide = geometry.size.width >= 1100 && !typeSize.isAccessibilitySize
            let panelWidth: CGFloat = 320
            let panelHeight = min(geometry.size.height, 540)
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        content().frame(maxWidth: .infinity, maxHeight: .infinity)
                        if visible && wide && !floating {
                            Divider()
                            panel(wide: wide).frame(width: panelWidth)
                        }
                    }
                    if visible && !wide {
                        Divider()
                        panel(wide: false).frame(height: min(expanded ? 520 : 300, geometry.size.height * (expanded ? 0.7 : 0.45)))
                    }
                }
                if visible && wide && floating {
                    panel(wide: true).frame(width: panelWidth, height: panelHeight)
                        .clipShape(RoundedRectangle(cornerRadius: Northstar.Radius.sm))
                        .overlay(RoundedRectangle(cornerRadius: Northstar.Radius.sm).stroke(Northstar.Palette.indicator))
                        .offset(x: min(0, max(-(geometry.size.width - panelWidth), offset.width + drag.width)),
                                y: max(0, min(geometry.size.height - panelHeight, offset.height + drag.height)))
                }
            }
        }
    }
    private func panel(wide: Bool) -> some View {
        VStack(spacing: 0) {
            if !wide {
                Button(expanded ? "Compact call panel" : "Expand call panel") { expanded.toggle() }
                    .frame(minHeight: 44)
            }
            if wide {
                HStack {
                    if floating {
                        Label("Move video", systemImage: "hand.draw").font(Northstar.Fonts.supporting)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .contentShape(Rectangle())
                            .gesture(DragGesture().updating($drag) { value, state, _ in state = value.translation }
                                .onEnded { value in offset.width += value.translation.width; offset.height += value.translation.height })
                            .accessibilityHidden(true)
                    }
                    Button(floating ? "Dock video" : "Float video") { floating.toggle(); offset = .zero }
                        .frame(minHeight: 44).padding(.horizontal, Northstar.Space.s2)
                }
            }
            WorkspaceCallPanel(compact: !wide || floating)
        }.background(Northstar.Palette.bgBase)
    }
}
