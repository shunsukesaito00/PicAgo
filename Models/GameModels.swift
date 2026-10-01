import Foundation
import PicAgoCore

struct GameQuestion: Identifiable, Equatable {
    let id: String
    let assetIdentifier: String
    let creationDate: Date
    let yearChoices: [Int]
    let correctYear: Int
    let includesBonusMonth: Bool
    let monthChoices: [Int]?
    let correctMonth: Int?

    init(from generated: GeneratedQuestion) {
        self.id = generated.assetIdentifier
        self.assetIdentifier = generated.assetIdentifier
        self.creationDate = generated.creationDate
        self.yearChoices = generated.yearChoices.choices
        self.correctYear = generated.yearChoices.correctYear
        self.includesBonusMonth = generated.includesBonusMonth
        self.monthChoices = generated.monthChoices?.choices
        self.correctMonth = generated.monthChoices?.correctMonth
    }

    init(
        id: String,
        assetIdentifier: String,
        creationDate: Date,
        yearChoices: [Int],
        correctYear: Int,
        includesBonusMonth: Bool = false,
        monthChoices: [Int]? = nil,
        correctMonth: Int? = nil
    ) {
        self.id = id
        self.assetIdentifier = assetIdentifier
        self.creationDate = creationDate
        self.yearChoices = yearChoices
        self.correctYear = correctYear
        self.includesBonusMonth = includesBonusMonth
        self.monthChoices = monthChoices
        self.correctMonth = correctMonth
    }
}

enum PhotoAuthorizationState: Equatable {
    case notDetermined
    case authorized
    case limited
    case denied
    case restricted
}

struct SharePayload {
    let score: MemoryScore
    let streak: Int
    let results: [Bool]

    func makeText(locale: Locale = .current) -> String {
        let blocks = results.map { $0 ? "🟩" : "🟥" }.joined()
        let tagline: String
        if locale.language.languageCode?.identifier == "ja" {
            tagline = "あなた、この写真いつ撮ったか覚えてる？"
        } else {
            tagline = "How well do you remember your photos?"
        }
        return """
        PicAgo
        Daily Memory
        \(blocks)
        \(score.displayFraction) \(score.percentage)%
        streak \(streak)
        \(tagline)
        """
    }
}
