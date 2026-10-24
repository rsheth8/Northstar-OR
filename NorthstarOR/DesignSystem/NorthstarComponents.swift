import SwiftUI

// Shared Northstar OR controls. Flat fills, visible pressed / disabled /
// focused states, Dynamic Type text and at least 44 pt (72 pt primary) targets.

/// Interaction state shown by a Northstar control. Button styles read it from
/// the environment; previews pass it directly to show every state.
struct NorthstarControlState: Equatable {
    var isPressed = false
    var isEnabled = true
    var isFocused = false
}

// MARK: - Primary action (72 x 72 pt minimum)

struct NorthstarPrimaryButtonStyle: ButtonStyle {
    enum Tone {
        /// Aurora: records a confirmation or completes the current item.
        case confirm
        /// Ice: the main action when it does not record a result,
        /// e.g. "Request support".
        case standard
    }

    var tone: Tone = .standard

    init(tone: Tone = .standard) {
        self.tone = tone
    }

    func makeBody(configuration: Configuration) -> some View {
        ControlStateReader(isPressed: configuration.isPressed) { state in
            NorthstarPrimaryButtonAppearance(tone: tone, state: state) {
                configuration.label
            }
        }
    }
}

struct NorthstarPrimaryButtonAppearance<Label: View>: View {
    let tone: NorthstarPrimaryButtonStyle.Tone
    let state: NorthstarControlState
    @ViewBuilder let label: Label

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Northstar.Radius.sm, style: .continuous)
    }

    private var fill: Color {
        guard state.isEnabled else { return Northstar.Palette.bgRaised }
        switch tone {
        case .confirm:  return state.isPressed ? Northstar.Palette.auroraPressed : Northstar.Palette.aurora
        case .standard: return state.isPressed ? Northstar.Palette.icePressed : Northstar.Palette.ice
        }
    }

    var body: some View {
        label
            .font(Northstar.Fonts.step)
            .multilineTextAlignment(.center)
            .foregroundStyle(state.isEnabled ? Northstar.Palette.onAurora : Northstar.Palette.inkMuted)
            .padding(.horizontal, Northstar.Space.s8)
            .padding(.vertical, Northstar.Space.s3)
            .frame(minWidth: Northstar.Target.primary, minHeight: Northstar.Target.primary)
            .background(fill, in: shape)
            .overlay {
                if !state.isEnabled {
                    shape.strokeBorder(Northstar.Palette.indicator, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                }
            }
            .contentShape(shape)
            .northstarFocusRing(state.isFocused, cornerRadius: Northstar.Radius.sm)
    }
}

// MARK: - Secondary action (outlined, 44 pt minimum)

struct NorthstarSecondaryButtonStyle: ButtonStyle {
    enum Size {
        /// 44 x 44 pt minimum, body text.
        case standard
        /// 72 x 72 pt minimum, for a quieter action beside a primary one.
        case large
    }

    var size: Size = .standard

    init(size: Size = .standard) {
        self.size = size
    }

    func makeBody(configuration: Configuration) -> some View {
        ControlStateReader(isPressed: configuration.isPressed) { state in
            NorthstarSecondaryButtonAppearance(size: size, state: state) {
                configuration.label
            }
        }
    }
}

struct NorthstarSecondaryButtonAppearance<Label: View>: View {
    let size: NorthstarSecondaryButtonStyle.Size
    let state: NorthstarControlState
    @ViewBuilder let label: Label

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Northstar.Radius.md, style: .continuous)
    }

    private var minimum: CGFloat {
        size == .large ? Northstar.Target.primary : Northstar.Target.minimum
    }

    // The pressed outline remains distinct from the neutral pressed surface.
    private var outline: StrokeStyle {
        StrokeStyle(lineWidth: 2, dash: state.isEnabled ? [] : [6, 4])
    }

    var body: some View {
        label
            .font(size == .large ? Northstar.Fonts.step : Northstar.Fonts.bodyStrong)
            .multilineTextAlignment(.center)
            .foregroundStyle(state.isEnabled ? Northstar.Palette.ink : Northstar.Palette.inkMuted)
            .padding(.horizontal, size == .large ? Northstar.Space.s6 : Northstar.Space.s4)
            .padding(.vertical, Northstar.Space.s2)
            .frame(minWidth: minimum, minHeight: minimum)
            .background(state.isPressed && state.isEnabled ? Northstar.Palette.slate : Color.clear, in: shape)
            .overlay {
                shape.strokeBorder(
                    state.isPressed && state.isEnabled ? Northstar.Palette.ink : Northstar.Palette.indicator,
                    style: outline
                )
            }
            .contentShape(shape)
            .northstarFocusRing(state.isFocused, cornerRadius: Northstar.Radius.md)
    }
}

private struct ControlStateReader<Content: View>: View {
    let isPressed: Bool
    @ViewBuilder let content: (NorthstarControlState) -> Content
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        content(NorthstarControlState(isPressed: isPressed, isEnabled: isEnabled, isFocused: isFocused))
    }
}

// MARK: - Status

/// Meaning of a status color. Always shown with an icon and a text label.
/// It describes recorded workflow or app state, never clinical readiness.
enum NorthstarTone: CaseIterable {
    /// Unrecorded, not requested, or otherwise neutral.
    case neutral
    /// Selection or information.
    case info
    /// A recorded confirmation or successful app action.
    case success
    /// Deferred or unresolved; needs attention.
    case attention
    /// Failed or blocked app action.
    case failure

    /// Text and icon color; at least 4.5:1 on bgBase, bgRaised and `background`.
    var foreground: Color {
        switch self {
        case .neutral:   Northstar.Palette.inkMuted
        case .info:      Northstar.Palette.ice
        case .success:   Northstar.Palette.aurora
        case .attention: Northstar.Palette.amber
        case .failure:   Northstar.Palette.alert
        }
    }

    /// Quiet fill for banners.
    var background: Color {
        switch self {
        case .neutral:   Northstar.Palette.bgRaised
        case .info:      Northstar.Palette.iceSoft
        case .success:   Northstar.Palette.auroraSoft
        case .attention: Northstar.Palette.amberSoft
        case .failure:   Northstar.Palette.alertSoft
        }
    }

    var defaultSymbol: String {
        switch self {
        case .neutral:   "circle"
        case .info:      "info.circle.fill"
        case .success:   "checkmark.circle.fill"
        case .attention: "exclamationmark.triangle.fill"
        case .failure:   "xmark.octagon.fill"
        }
    }
}

/// Icon plus label for a recorded state, e.g. "Deferred" or "Awaiting acceptance".
struct NorthstarStatusLabel: View {
    let title: String
    let tone: NorthstarTone
    var systemImage: String?

    init(_ title: String, tone: NorthstarTone, systemImage: String? = nil) {
        self.title = title
        self.tone = tone
        self.systemImage = systemImage
    }

    var body: some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: systemImage ?? tone.defaultSymbol)
                .accessibilityHidden(true)
        }
        .font(Northstar.Fonts.label)
        .foregroundStyle(tone.foreground)
        .accessibilityElement(children: .combine)
    }
}

/// Persistent banner for an attention item or failure: the named condition,
/// its consequence for the app workflow and an optional action.
struct NorthstarBanner: View {
    let tone: NorthstarTone
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(
        tone: NorthstarTone,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.tone = tone
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Northstar.Radius.sm, style: .continuous)
    }

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Northstar.Space.s4))
            : AnyLayout(HStackLayout(alignment: .center, spacing: Northstar.Space.s4))

        layout {
            HStack(alignment: .firstTextBaseline, spacing: Northstar.Space.s3) {
                Image(systemName: tone.defaultSymbol)
                    .font(Northstar.Fonts.bodyStrong)
                    .foregroundStyle(tone.foreground)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Northstar.Space.s1) {
                    Text(title)
                        .font(Northstar.Fonts.bodyStrong)
                        .foregroundStyle(tone.foreground)
                    Text(message)
                        .font(Northstar.Fonts.body)
                        .foregroundStyle(Northstar.Palette.ink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityElement(children: .combine)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(NorthstarSecondaryButtonStyle())
            }
        }
        .padding(Northstar.Space.s4)
        .background(tone.background, in: shape)
        .overlay { shape.strokeBorder(tone.foreground, lineWidth: 2) }
    }
}

// MARK: - Modifiers

extension View {
    /// Focus ring drawn 2 pt outside the control so it contrasts with the
    /// surface behind it rather than with the control's own fill.
    func northstarFocusRing(_ isVisible: Bool, cornerRadius: CGFloat) -> some View {
        overlay {
            RoundedRectangle(cornerRadius: cornerRadius + 5, style: .continuous)
                .strokeBorder(Northstar.Palette.focusRing, lineWidth: 3)
                .padding(-5)
                .opacity(isVisible ? 1 : 0)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    /// Expands the hit area to at least `minimum` points in each direction
    /// without changing how the content looks.
    func northstarHitTarget(_ minimum: CGFloat = Northstar.Target.minimum) -> some View {
        frame(minWidth: minimum, minHeight: minimum)
            .contentShape(Rectangle())
    }

    /// Animates a state change briefly, or not at all with Reduce Motion.
    func northstarStateAnimation<Value: Equatable>(value: Value) -> some View {
        modifier(NorthstarStateAnimation(value: value))
    }
}

private struct NorthstarStateAnimation<Value: Equatable>: ViewModifier {
    let value: Value
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.animation(Northstar.Motion.stateChange(reduceMotion: reduceMotion), value: value)
    }
}
