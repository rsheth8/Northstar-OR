import SwiftUI

// Shared Northstar OR design tokens. Light working surfaces and a midnight identity strip.

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

enum Northstar {

    // MARK: Light workspace colors
    // Compatibility names let existing views adopt the measured light pairs.
    // The midnight identity strip uses Workspace.header/onHeader explicitly.
    enum Palette {
        static let bgBase = Workspace.canvas
        static let bgRaised = Workspace.surface
        static let bgSunken = Workspace.surfaceSubtle
        static let slate = Workspace.secondaryPressed
        static let line = Workspace.divider
        static let ink = Workspace.text
        static let inkMuted = Workspace.textSecondary
        static let starlight = Workspace.selectionIndicator
        static let starCore = Workspace.onHeader
        static let aurora = Workspace.success
        static let auroraSoft = Workspace.successSurface
        static let onAurora = Workspace.onAction
        static let ice = Workspace.action
        static let amber = Workspace.attention
        static let amberSoft = Workspace.attentionSurface
        static let alert = Workspace.failure
        static let indicator = Workspace.boundary
        static let focusRing = Workspace.focus
        static let auroraPressed = Color(hex: 0x105033) // Distinct pressed confirmation fill.
        static let icePressed = Workspace.actionPressed
        static let iceSoft = Workspace.selection
        static let alertSoft = Workspace.failureSurface
    }

    // MARK: Spacing
    enum Space {
        static let s1: CGFloat = 4
        static let s2: CGFloat = 8
        static let s3: CGFloat = 12
        static let s4: CGFloat = 16
        static let s6: CGFloat = 24
        static let s8: CGFloat = 32
        static let s12: CGFloat = 48
    }

    // MARK: Touch targets
    enum Target {
        /// Primary OR actions: at least 72 x 72 pt.
        static let primary: CGFloat = 72
        /// Every other interactive element: at least 44 x 44 pt.
        static let minimum: CGFloat = 44
        /// Space between adjacent hit areas.
        static let spacing: CGFloat = Space.s2
    }

    // MARK: Motion
    enum Motion {
        /// Brief state transitions only; no looping or decorative motion.
        static let duration: Double = 0.15

        /// `nil` when Reduce Motion is on, so the change applies instantly.
        static func stateChange(reduceMotion: Bool) -> Animation? {
            reduceMotion ? nil : .easeOut(duration: duration)
        }
    }

    // MARK: Radius
    enum Radius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 10
        static let lg: CGFloat = 12
    }

    // MARK: Type
    // Built on text styles so every token scales with Dynamic Type.
    // Sizes in comments are the defaults at the Large content size.
    enum Fonts {
        static let display     = Font.system(.largeTitle, weight: .semibold)              // 34
        static let stepCurrent = Font.system(.largeTitle, weight: .semibold)              // 34
        static let title       = Font.system(.title2, weight: .semibold)                  // 22
        static let step        = Font.system(.title2, weight: .semibold)                  // 22
        static let body        = Font.system(.body)                                       // 17
        static let bodyStrong  = Font.system(.body, weight: .semibold)                    // 17
        static let caption     = Font.system(.footnote, weight: .medium)                  // 13
        static let label       = Font.system(.footnote, weight: .semibold)                // 13
        /// Supporting metadata: the 13 pt baseline in regular weight.
        static let supporting  = Font.system(.footnote)                                   // 13
        static let log         = Font.system(.subheadline)  // 15
        static let timer       = Font.system(.title, design: .monospaced, weight: .semibold)      // 28
    }
}
