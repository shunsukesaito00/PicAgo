import Foundation
import CoreGraphics

#if canImport(UIKit)
import UIKit
#endif

/// Minimal photo asset metadata. Never persist image bytes — only identifiers + dates.
struct PhotoAssetInfo: Identifiable, Equatable, Sendable {
    let id: String
    let creationDate: Date

    var assetIdentifier: String { id }
}

protocol PhotoLibraryServing: AnyObject {
    var authorizationState: PhotoAuthorizationState { get }
    func refreshAuthorizationState()
    func requestAuthorization() async -> PhotoAuthorizationState
    func fetchEligibleAssets() async -> [PhotoAssetInfo]
    func requestImage(
        for assetIdentifier: String,
        targetSize: CGSize
    ) async -> PlatformImage?
    func openSystemSettings()
}

#if canImport(UIKit)
typealias PlatformImage = UIImage
#else
struct PlatformImage: Equatable {}
#endif

/// Production PhotoKit-backed service. Compiles only where Photos is available.
#if canImport(Photos) && canImport(UIKit)
import Photos
import UIKit

@MainActor
final class PhotoLibraryService: PhotoLibraryServing {
    private let cachingManager = PHCachingImageManager()
    private(set) var authorizationState: PhotoAuthorizationState = .notDetermined

    init() {
        refreshAuthorizationState()
        cachingManager.allowsCachingHighQualityImages = false
    }

    func refreshAuthorizationState() {
        authorizationState = Self.map(PHPhotoLibrary.authorizationStatus(for: .readWrite))
    }

    func requestAuthorization() async -> PhotoAuthorizationState {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        let mapped = Self.map(status)
        authorizationState = mapped
        return mapped
    }

    func fetchEligibleAssets() async -> [PhotoAssetInfo] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let options = PHFetchOptions()
                options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
                let result = PHAsset.fetchAssets(with: options)
                var assets: [PhotoAssetInfo] = []
                assets.reserveCapacity(result.count)
                result.enumerateObjects { asset, _, _ in
                    guard let date = asset.creationDate else { return }
                    assets.append(PhotoAssetInfo(id: asset.localIdentifier, creationDate: date))
                }
                continuation.resume(returning: assets)
            }
        }
    }

    func requestImage(for assetIdentifier: String, targetSize: CGSize) async -> PlatformImage? {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
        guard let asset = assets.firstObject else { return nil }

        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        return await withCheckedContinuation { continuation in
            var hasResumed = false
            cachingManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                let cancelled = (info?[PHImageCancelledKey] as? Bool) ?? false
                let degraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if cancelled {
                    if !hasResumed {
                        hasResumed = true
                        continuation.resume(returning: nil)
                    }
                    return
                }
                // Prefer the final (non-degraded) callback when available.
                if degraded { return }
                if !hasResumed {
                    hasResumed = true
                    continuation.resume(returning: image)
                }
            }
        }
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private static func map(_ status: PHAuthorizationStatus) -> PhotoAuthorizationState {
        switch status {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        case .authorized: return .authorized
        case .limited: return .limited
        @unknown default: return .denied
        }
    }
}
#endif
