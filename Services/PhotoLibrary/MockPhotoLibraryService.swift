import Foundation
import CoreGraphics

#if canImport(UIKit)
import UIKit
#endif

/// Preview / test double. Never embeds real user photos.
@MainActor
final class MockPhotoLibraryService: PhotoLibraryServing {
    var authorizationState: PhotoAuthorizationState
    var eligibleAssets: [PhotoAssetInfo]
    var didRequestAuthorization = false
    var didOpenSettings = false

    init(
        authorizationState: PhotoAuthorizationState = .authorized,
        assetCount: Int = 12
    ) {
        self.authorizationState = authorizationState
        let calendar = Calendar(identifier: .gregorian)
        self.eligibleAssets = (0..<assetCount).compactMap { index in
            var components = DateComponents()
            components.year = 2016 + (index % 8)
            components.month = (index % 12) + 1
            components.day = 5 + (index % 20)
            components.hour = index % 12
            guard let date = calendar.date(from: components) else { return nil }
            return PhotoAssetInfo(id: "mock-asset-\(index)", creationDate: date)
        }
    }

    func refreshAuthorizationState() {}

    func requestAuthorization() async -> PhotoAuthorizationState {
        didRequestAuthorization = true
        if authorizationState == .notDetermined {
            authorizationState = .authorized
        }
        return authorizationState
    }

    func fetchEligibleAssets() async -> [PhotoAssetInfo] {
        switch authorizationState {
        case .authorized, .limited:
            return eligibleAssets
        case .denied, .restricted, .notDetermined:
            return []
        }
    }

    func requestImage(for assetIdentifier: String, targetSize: CGSize) async -> PlatformImage? {
        #if canImport(UIKit)
        PlaceholderImageFactory.make(size: targetSize, seed: assetIdentifier.hashValue)
        #else
        nil
        #endif
    }

    func openSystemSettings() {
        didOpenSettings = true
    }
}

#if canImport(UIKit)
import UIKit

enum PlaceholderImageFactory {
    static func make(size: CGSize, seed: Int) -> UIImage {
        let width = max(Int(size.width), 120)
        let height = max(Int(size.height), 160)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        return renderer.image { context in
            let hues: [CGFloat] = [0.08, 0.12, 0.55, 0.62, 0.35]
            let hue = hues[abs(seed) % hues.count]
            UIColor(hue: hue, saturation: 0.25, brightness: 0.85, alpha: 1).setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))

            UIColor.white.withAlphaComponent(0.35).setFill()
            let inset = CGRect(x: width / 6, y: height / 5, width: width * 2 / 3, height: height / 2)
            UIBezierPath(roundedRect: inset, cornerRadius: 12).fill()
        }
    }
}
#endif
