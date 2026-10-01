import Foundation

enum FeatureFlags {
    /// Bonus "what month?" questions after a correct year answer.
    /// Toggle off to ship year-only MVP experience.
    static var bonusMonthQuestionsEnabled: Bool = true

    /// Extension-point only — no AdMob SDK in MVP.
    static var adsEnabled: Bool = false

    /// Extension-point only — no StoreKit products in MVP.
    static var purchasesEnabled: Bool = false
}
