import Foundation

/// Extension point for a future StoreKit 2 integration. No products in MVP.
protocol PurchaseServing: AnyObject {
    var isEnabled: Bool { get }
    func refreshEntitlements() async
    var hasRemovedAds: Bool { get }
}

final class NoOpPurchaseService: PurchaseServing {
    var isEnabled: Bool { FeatureFlags.purchasesEnabled }
    private(set) var hasRemovedAds: Bool = false

    func refreshEntitlements() async {
        // Intentionally empty — Product.products / Transaction.updates later.
    }
}
