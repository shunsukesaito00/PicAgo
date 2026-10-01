import Foundation
import SwiftUI

@MainActor
@Observable
final class AppSession {
    enum Route: Equatable {
        case onboarding
        case home
        case game
        case result
    }

    var route: Route
    var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: Keys.onboarding) }
    }

    let photoLibrary: any PhotoLibraryServing
    let ads: any AdServing
    let purchases: any PurchaseServing

    var lastResultShare: SharePayload?
    var lastBonusCorrect: Int = 0

    init(
        photoLibrary: any PhotoLibraryServing,
        ads: any AdServing = NoOpAdService(),
        purchases: any PurchaseServing = NoOpPurchaseService()
    ) {
        self.photoLibrary = photoLibrary
        self.ads = ads
        self.purchases = purchases
        let onboarded = UserDefaults.standard.bool(forKey: Keys.onboarding)
        self.hasCompletedOnboarding = onboarded
        self.route = onboarded ? .home : .onboarding
        photoLibrary.refreshAuthorizationState()
    }

    func finishOnboarding() {
        hasCompletedOnboarding = true
        route = .home
    }

    func startGame() {
        route = .game
    }

    func showResult(share: SharePayload, bonusCorrect: Int) {
        lastResultShare = share
        lastBonusCorrect = bonusCorrect
        ads.recordInterstitialOpportunity()
        route = .result
    }

    func returnHome() {
        route = .home
    }

    private enum Keys {
        static let onboarding = "picago.hasCompletedOnboarding"
    }
}
