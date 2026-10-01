import Foundation

/// Extension point for a future AdMob integration. No SDK linked in MVP.
protocol AdServing: AnyObject {
    var isEnabled: Bool { get }
    func prepareBannerIfNeeded()
    func recordInterstitialOpportunity()
}

final class NoOpAdService: AdServing {
    var isEnabled: Bool { FeatureFlags.adsEnabled }

    func prepareBannerIfNeeded() {
        // Intentionally empty — wire AdMob Mobile Ads SDK here later.
    }

    func recordInterstitialOpportunity() {
        // Intentionally empty — call interstitial presentation rules later.
    }
}
