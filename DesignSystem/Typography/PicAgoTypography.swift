import SwiftUI

enum PicAgoTypography {
    static let brand = Font.system(.largeTitle, design: .default).weight(.bold)
    static let hero = Font.system(.title, design: .default).weight(.semibold)
    static let title = Font.system(.title2, design: .default).weight(.semibold)
    static let headline = Font.system(.headline, design: .default)
    static let body = Font.system(.body, design: .default)
    static let callout = Font.system(.callout, design: .default)
    static let caption = Font.system(.caption, design: .default)
    static let yearChoice = Font.system(.title2, design: .rounded).weight(.semibold)
}
