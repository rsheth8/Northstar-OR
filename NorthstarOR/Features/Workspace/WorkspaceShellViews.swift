import SwiftUI

/// Quiet placeholder while the store is read.
struct WorkspaceLoadingView: View {
    var body: some View {
        VStack(spacing: Northstar.Space.s4) {
            ProgressView()
            Text("Opening workspace").font(Northstar.Fonts.supporting)
                .foregroundStyle(Northstar.Palette.inkMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Northstar.Palette.bgBase)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("workspace-loading")
    }
}

/// Saved data cannot be opened. Explains why and offers only actions that exist.
struct WorkspaceBlockedView: View {
    let message: String
    let canRetry: Bool
    let canSetAside: Bool
    let onRetry: () -> Void
    let onSetAside: () throws -> Void

    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: Northstar.Space.s6) {
            NorthstarBanner(tone: .failure, title: "Saved data can't be opened", message: message)
            if let errorMessage {
                NorthstarBanner(tone: .failure, title: "Not changed", message: errorMessage)
                    .accessibilityIdentifier("blocked-error")
            }
            HStack(spacing: Northstar.Space.s4) {
                if canRetry {
                    Button("Retry", action: onRetry)
                        .buttonStyle(NorthstarSecondaryButtonStyle())
                        .accessibilityIdentifier("blocked-retry")
                }
                if canSetAside {
                    Button("Set aside and start fresh") {
                        do { try onSetAside(); errorMessage = nil } catch {
                            errorMessage = WorkspaceForms.message(for: error)
                        }
                    }
                    .buttonStyle(NorthstarSecondaryButtonStyle())
                    .accessibilityIdentifier("blocked-set-aside")
                }
            }
            if canSetAside {
                Text("Setting aside keeps the old data on this device, separate from the app, and starts a new workspace.")
                    .font(Northstar.Fonts.supporting)
                    .foregroundStyle(Northstar.Palette.inkMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: 560)
        .padding(Northstar.Space.s6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Northstar.Palette.bgBase)
        .accessibilityIdentifier("workspace-blocked")
    }
}

/// Persistent, non-blocking notice shown while the last save has not succeeded.
struct SaveFailureBanner: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        NorthstarBanner(tone: .failure, title: "Not saved", message: message,
                        actionTitle: "Retry save", action: onRetry)
            .padding(.horizontal, Northstar.Space.s6)
            .padding(.vertical, Northstar.Space.s2)
            .background(Northstar.Palette.bgBase)
            .accessibilityIdentifier("save-failure-banner")
    }
}
