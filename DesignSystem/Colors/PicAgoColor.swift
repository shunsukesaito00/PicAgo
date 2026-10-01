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
    static let photoScrim = Color.black.opacity(0.28)
    static let success = Color(red: 0.22, green: 0.62, blue: 0.40)
    static let subtleFill = Color.primary.opacity(0.06)
}
