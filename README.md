# PicAgo

自分のiPhone写真で遊ぶ Daily Memory Game（MVP）。

「この写真、何年に撮った？」— 1日5問。写真は端末の外に出ません。

## Requirements

- macOS with **Xcode 15+** (iOS 17 SDK)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- Homebrew (recommended)

## Generate & open (Mac)

```bash
brew install xcodegen
cd PicAgo
xcodegen generate
open PicAgo.xcodeproj
```

Select an iPhone Simulator or device, then Run (⌘R).

### First-run notes

1. Onboarding explains why photos are needed **before** the system permission dialog.
2. Tap **写真から遊んでみる / Play with my photos** to trigger `PHPhotoLibrary` authorization.
3. Limited Photo Access is supported — you can still play with the allowed set (need ≥ 4 dated photos).

## Photo permission copy (`NSPhotoLibraryUsageDescription`)

| Language | Text |
|----------|------|
| **English** | PicAgo uses your photo library to show your own memories in a daily year-guessing game. Photos stay on your iPhone and are never uploaded. |
| **日本語** | PicAgoは、あなたの写真ライブラリを使って「撮影年当て」デイリーゲームを表示します。写真はこのiPhone内に留まり、外部へ送信しません。 |

Localized via `Localization/InfoPlist.xcstrings` (and mirrored in `Resources/Info.plist` for the development region).

## Project layout

```
PicAgo/
  App/                 # SwiftUI entry + session routing
  Features/            # Onboarding, Home, Game, Result (MVVM)
  Services/            # PhotoLibrary (+ mocks), Ads/Purchases extension points
  Models/              # Feature flags, game models
  Persistence/         # SwiftData streak + daily records
  DesignSystem/        # Color, type, spacing, components
  Localization/        # String Catalog JA/EN
  Resources/           # Info.plist, Assets
  PicAgoCore/          # Pure Swift package (Linux-testable game logic)
  project.yml          # XcodeGen spec
```

## PicAgoCore tests (Linux / CI)

Game logic has **no UIKit/PhotoKit** dependency:

```bash
cd PicAgo/PicAgoCore
swift test
```

## Feature flags

`Models/FeatureFlags.swift`:

- `bonusMonthQuestionsEnabled` — after a correct year, optional “which month?” (max 1–2 / day). Does **not** affect Memory Score.
- `adsEnabled` / `purchasesEnabled` — extension points only; **no AdMob or StoreKit SDK** in MVP (`NoOpAdService`, `NoOpPurchaseService`).

## Privacy

- Photos are never uploaded, deleted, or modified.
- Only `PHAsset` local identifiers + creation dates are used in game state.
- Image bytes are not persisted by PicAgo.
- Share sheet sends **score text only** (no photo, location, or capture date).

## DEBUG

Home shows a **DEBUG Reset Today** control in Debug builds only (developer menu). Production builds cannot reset a completed daily challenge.

## Brand

- Name: **PicAgo** (JA/EN, do not rename)
- JA tagline: あなた、この写真いつ撮ったか覚えてる？
- EN tagline: How well do you remember your photos?
