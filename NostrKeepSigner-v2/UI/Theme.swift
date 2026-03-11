import SwiftUI

/// Monokai-inspired color theme matching the NostrKey browser extension
enum NostrKeyTheme {
    // MARK: - Background
    static let bg = Color("MonokaiBg")              // #272822
    static let bgLight = Color("MonokaiBgLight")    // #3E3D32

    // MARK: - Accent (primary interactive color)
    static let accent = Color("AccentColor")         // #A6E22E (Monokai green)
    static let accentHover = Color(hex: 0xB8F339)    // Lighter green

    // MARK: - Semantic Colors
    static let orange = Color("MonokaiOrange")       // #FD971F
    static let red = Color("MonokaiRed")             // #F92672
    static let cyan = Color("MonokaiCyan")           // #66D9EF
    static let brown = Color("MonokaiBrown")         // #8B7355
    static let yellow = Color(hex: 0xE6DB74)         // #E6DB74

    // MARK: - Text
    static let text = Color(hex: 0xF8F8F2)           // #F8F8F2
    static let textMuted = Color(hex: 0xB0B0A8)      // #B0B0A8
}

// MARK: - Hex Color Initializer

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}
