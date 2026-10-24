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

    // MARK: Radius
    enum Radius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 10
        static let lg: CGFloat = 12
    }

    // MARK: Type
    enum Fonts {
        static let display     = Font.system(size: 40, weight: .semibold)
        static let stepCurrent = Font.system(size: 32, weight: .semibold)
        static let title       = Font.system(size: 24, weight: .semibold)
        static let step        = Font.system(size: 22, weight: .semibold)
        static let body        = Font.system(size: 17, weight: .regular)
        static let bodyStrong  = Font.system(size: 17, weight: .semibold)
        static let caption     = Font.system(size: 13, weight: .medium)
        static let label       = Font.system(size: 12, weight: .bold)
        static let log         = Font.system(size: 15, weight: .medium, design: .monospaced)
        static let timer       = Font.system(size: 28, weight: .semibold, design: .monospaced)
    }
}

// MARK: Primary action button (aurora, glove-friendly, 72pt tall)
struct NorthstarPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Northstar.Fonts.step)
            .foregroundStyle(Northstar.Palette.onAurora)
            .padding(.horizontal, Northstar.Space.s8)
            .frame(minHeight: 72)
            .background(
                Northstar.Palette.aurora,
                in: RoundedRectangle(cornerRadius: Northstar.Radius.lg, style: .continuous)
            )
            .opacity(configuration.isPressed ? 0.82 : 1)
    }
}
