import SwiftUI

enum PicAgoColor {
    /// Brand accent — warm coral / amber from asset catalog (fallback if missing).
    static let accent = Color("BrandCoral")
    static let brandFallback = Color(red: 0.86, green: 0.42, blue: 0.30)
    static let brandSoft = Color(red: 0.93, green: 0.58, blue: 0.42)

    static let ink = Color.primary
    static let inkSecondary = Color.secondary
    static let surface = Color(.systemBackground)
    static let surfaceElevated = Color(.secondarySystemBackground)
    /// Readable overlay on photos (Light/Dark).
    static let photoScrim = Color.black.opacity(0.45)
    static let success = Color(red: 0.22, green: 0.62, blue: 0.40)
    static let subtleFill = Color.primary.opacity(0.06)

    /// Year/month choice tiles on the dark Game canvas — keep contrast high.
    static let choiceFill = Color.white.opacity(0.94)
    static let choiceFillMuted = Color.white.opacity(0.38)
    static let choiceInk = Color(red: 0.16, green: 0.13, blue: 0.11)
    static let choiceInkMuted = Color.white.opacity(0.78)
}
