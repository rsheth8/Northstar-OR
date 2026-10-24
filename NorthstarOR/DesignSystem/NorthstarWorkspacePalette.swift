import SwiftUI

extension Northstar.Palette {
    /// Opt-in light workspace foundation. Migrate each screen and its controls
    /// together; legacy Palette tokens still serve the existing dark screens.
    /// Opaque sRGB pairs and measurements: docs/evidence/light-workspace/.
    enum Workspace {
        static let canvas = Color(hex: 0xF4F6F8)
        static let surface = Color(hex: 0xFFFFFF)
        static let surfaceSubtle = Color(hex: 0xEDF1F5)
        static let divider = Color(hex: 0xD4DBE3) // Decorative, not a control boundary.
        static let text = Color(hex: 0x202B38)
        static let textSecondary = Color(hex: 0x526171)
        static let boundary = Color(hex: 0x758394) // Essential non-text outlines.

        static let header = Color(hex: 0x142D43)
        static let onHeader = Color(hex: 0xFFFFFF)
        static let onHeaderSecondary = Color(hex: 0xCFDCE7)

        static let action = Color(hex: 0x174F85)
        static let actionPressed = Color(hex: 0x103D69)
        static let onAction = Color(hex: 0xFFFFFF)
        static let selection = Color(hex: 0xE5EFF9)
        static let selectionIndicator = Color(hex: 0x185A9D)
        static let focus = Color(hex: 0x185A9D) // Draw outside fill with a gap.
        static let secondaryPressed = Color(hex: 0xE2E8EF)
        static let disabledSurface = Color(hex: 0xEDF1F5)
        static let disabledText = Color(hex: 0x526171)

        // Always pair these with an icon and a recorded-state label.
        static let success = Color(hex: 0x176842)
        static let successSurface = Color(hex: 0xEAF4EE)
        static let attention = Color(hex: 0x825200)
        static let attentionSurface = Color(hex: 0xFFF3D9)
        static let failure = Color(hex: 0xA52932)
        static let failureSurface = Color(hex: 0xFCEDEF)
        static let information = Color(hex: 0x174F85)
        static let informationSurface = Color(hex: 0xE5EFF9)
    }
}
