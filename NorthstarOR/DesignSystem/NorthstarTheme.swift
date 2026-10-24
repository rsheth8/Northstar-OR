import SwiftUI

// Shared Northstar OR design tokens. Dark theme is primary.

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

    // MARK: Colors (dark theme)
    enum Palette {
        static let bgBase     = Color(hex: 0x0B1220)
        static let bgRaised   = Color(hex: 0x141E2C)
        static let bgSunken   = Color(hex: 0x070C17)
        static let slate      = Color(hex: 0x2A394B)
        static let line       = Color(hex: 0x283547)
        static let ink        = Color(hex: 0xE8F1F8)
        static let inkMuted   = Color(hex: 0x9BB0C4)
        static let starlight  = Color(hex: 0xF9D98A)  // logo star (updated)
        static let starCore   = Color(hex: 0xFFF6DC)  // hot centre of the star
        static let aurora     = Color(hex: 0x3DDC97)
        static let auroraSoft = Color(hex: 0x12342F)
        static let onAurora   = Color(hex: 0x0B1220)
        static let ice        = Color(hex: 0x7FC4E8)
        static let amber      = Color(hex: 0xFFB020)
        static let amberSoft  = Color(hex: 0x3A2A0A)
        static let alert      = Color(hex: 0xFF6B6B)

        // Readable state colors. Measured with the WCAG formula against
        // bgBase / bgRaised; see docs/DESIGN.md section 7 for the targets.
        /// Neutral icons, outlines and boundaries that carry meaning
        /// (4.66:1 / 4.18:1). Non-text only; use `inkMuted` for text.
        /// `slate` and `line` stay decorative (about 1.5:1).
        static let indicator     = Color(hex: 0x6B819A)
        /// Keyboard focus ring. Drawn outside the control with a gap so it
        /// contrasts with the surface (9.77:1 / 8.76:1), not the fill.
        static let focusRing     = ice
        static let auroraPressed = Color(hex: 0x2FB97C)  // onAurora text 7.45:1
        static let icePressed    = Color(hex: 0x5FA8CF)  // onAurora text 7.12:1
        static let iceSoft       = Color(hex: 0x12283A)  // ice text 7.89:1
        static let alertSoft     = Color(hex: 0x3A1518)  // alert text 5.82:1
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
        static let log         = Font.system(.subheadline, design: .monospaced, weight: .medium)  // 15
        static let timer       = Font.system(.title, design: .monospaced, weight: .semibold)      // 28
    }
}
