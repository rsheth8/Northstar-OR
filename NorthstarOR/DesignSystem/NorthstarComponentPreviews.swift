import SwiftUI

#if DEBUG
// Component evidence for review: type ramp, every control state, status tones
// and banners. Fictional, non-clinical copy only.

struct NorthstarComponentGallery: View {
    private let states: [(String, NorthstarControlState)] = [
        ("Default", .init()),
        ("Pressed", .init(isPressed: true)),
        ("Focused", .init(isFocused: true)),
        ("Disabled", .init(isEnabled: false)),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Northstar.Space.s8) {
                section("Type") {
                    Text("Current item title").font(Northstar.Fonts.stepCurrent)
                    Text("Section title").font(Northstar.Fonts.title)
                    Text("Body text for a recorded confirmation.").font(Northstar.Fonts.body)
                    Text("Supporting metadata · 14:32 CT").font(Northstar.Fonts.supporting)
                        .foregroundStyle(Northstar.Palette.inkMuted)
                    Text("SECTION LABEL").font(Northstar.Fonts.label)
                        .foregroundStyle(Northstar.Palette.inkMuted)
                    Text("14:32:05  Item 3 recorded").font(Northstar.Fonts.log)
                }

                section("Primary: confirm") {
                    stateRow { NorthstarPrimaryButtonAppearance(tone: .confirm, state: $0) { Text("Record confirmation") } }
                }
                section("Primary: standard") {
                    stateRow { NorthstarPrimaryButtonAppearance(tone: .standard, state: $0) { Text("Request support") } }
                }
                section("Secondary") {
                    stateRow { NorthstarSecondaryButtonAppearance(size: .standard, state: $0) { Text("Defer item") } }
                    stateRow { NorthstarSecondaryButtonAppearance(size: .large, state: $0) { Text("Defer item") } }
                }

                section("Live styles") {
                    HStack(spacing: Northstar.Target.spacing) {
                        Button("Record confirmation") {}
                            .buttonStyle(NorthstarPrimaryButtonStyle())
                        Button("Request support") {}
                            .buttonStyle(NorthstarPrimaryButtonStyle(tone: .standard))
                        Button("Defer item") {}
                            .buttonStyle(NorthstarSecondaryButtonStyle(size: .large))
                        Button {} label: {
                            Image(systemName: "ellipsis")
                                .accessibilityLabel("More actions")
                        }
                        .buttonStyle(NorthstarSecondaryButtonStyle())
                    }
                }

                section("Status") {
                    NorthstarStatusLabel("Unrecorded", tone: .neutral)
                    NorthstarStatusLabel("On this device", tone: .info, systemImage: "ipad.landscape")
                    NorthstarStatusLabel("Team-confirmed", tone: .success)
                    NorthstarStatusLabel("Deferred", tone: .attention)
                    NorthstarStatusLabel("Send failed", tone: .failure)
                    HStack(spacing: Northstar.Space.s3) {
                        Image(systemName: "circle")
                            .foregroundStyle(Northstar.Palette.indicator)
                            .accessibilityHidden(true)
                        Text("Neutral indicator icon on bgBase")
                            .font(Northstar.Fonts.supporting)
                            .foregroundStyle(Northstar.Palette.inkMuted)
                    }
                }

                section("Banners") {
                    NorthstarBanner(
                        tone: .attention,
                        title: "Item 4 deferred",
                        message: "Acknowledgment required before recording another item.",
                        actionTitle: "Acknowledge",
                        action: {}
                    )
                    NorthstarBanner(
                        tone: .failure,
                        title: "Request not sent",
                        message: "Your question is kept. Retry or edit it.",
                        actionTitle: "Retry",
                        action: {}
                    )
                    NorthstarBanner(
                        tone: .info,
                        title: "On this device",
                        message: "Support messages stay in this app until a connection is set up."
                    )
                }
            }
            .padding(Northstar.Space.s6)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(Northstar.Palette.ink)
        .background(Northstar.Palette.bgBase)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Northstar.Space.s4) {
            Text(title.uppercased())
                .font(Northstar.Fonts.label)
                .foregroundStyle(Northstar.Palette.inkMuted)
                .accessibilityAddTraits(.isHeader)
            content()
        }
    }

    // Wraps onto further rows when the window or text size runs out of width.
    private func stateRow<Control: View>(@ViewBuilder control: @escaping (NorthstarControlState) -> Control) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: Northstar.Space.s6) { stateCells(control) }
            VStack(alignment: .leading, spacing: Northstar.Space.s4) { stateCells(control) }
        }
    }

    @ViewBuilder
    private func stateCells<Control: View>(_ control: @escaping (NorthstarControlState) -> Control) -> some View {
        ForEach(states.indices, id: \.self) { index in
            let (name, state) = states[index]
            VStack(alignment: .leading, spacing: Northstar.Space.s2) {
                control(state)
                Text(name)
                    .font(Northstar.Fonts.supporting)
                    .foregroundStyle(Northstar.Palette.inkMuted)
            }
        }
    }
}

#Preview("Components · default text", traits: .landscapeLeft) {
    NorthstarComponentGallery()
}

#Preview("Components · XXXL", traits: .landscapeLeft) {
    NorthstarComponentGallery()
        .environment(\.dynamicTypeSize, .xxxLarge)
}

#Preview("Components · largest accessibility", traits: .landscapeLeft) {
    NorthstarComponentGallery()
        .environment(\.dynamicTypeSize, .accessibility5)
}
#endif
