import Foundation
import SwiftData
import PicAgoCore

@Model
final class StreakRecord {
    var currentStreak: Int
    var longestStreak: Int
    var lastCompletedDate: Date?
    var bestScore: Int
    var yesterdayScore: Int?
    var todayScore: Int?

    init(
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastCompletedDate: Date? = nil,
        bestScore: Int = 0,
        yesterdayScore: Int? = nil,
        todayScore: Int? = nil
    ) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastCompletedDate = lastCompletedDate
        self.bestScore = bestScore
        self.yesterdayScore = yesterdayScore
        self.todayScore = todayScore
    }

    func asState() -> StreakState {
        StreakState(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            lastCompletedDate: lastCompletedDate,
            bestScore: bestScore,
            yesterdayScore: yesterdayScore,
            todayScore: todayScore
        )
    }

    func apply(_ state: StreakState) {
        currentStreak = state.currentStreak
        longestStreak = state.longestStreak
        lastCompletedDate = state.lastCompletedDate
        bestScore = state.bestScore
        yesterdayScore = state.yesterdayScore
        todayScore = state.todayScore
    }
}

@Model
final class DailyChallengeRecord {
    var challengeDay: Date
    var assetIdentifiersCSV: String
    var yearAnswersCSV: String
    var bonusMonthCorrectCount: Int
    var isCompleted: Bool
    var scoreCorrectCount: Int

    init(
        challengeDay: Date,
        assetIdentifiers: [String] = [],
        yearAnswers: [Bool] = [],
        bonusMonthCorrectCount: Int = 0,
        isCompleted: Bool = false,
        scoreCorrectCount: Int = 0
    ) {
        self.challengeDay = DateLogic.startOfDay(challengeDay)
        self.assetIdentifiersCSV = assetIdentifiers.joined(separator: ",")
        self.yearAnswersCSV = yearAnswers.map { $0 ? "1" : "0" }.joined(separator: ",")
        self.bonusMonthCorrectCount = bonusMonthCorrectCount
        self.isCompleted = isCompleted
        self.scoreCorrectCount = scoreCorrectCount
    }

    var assetIdentifiers: [String] {
        assetIdentifiersCSV.isEmpty ? [] : assetIdentifiersCSV.split(separator: ",").map(String.init)
    }

    var yearAnswers: [Bool] {
        yearAnswersCSV.isEmpty ? [] : yearAnswersCSV.split(separator: ",").map { $0 == "1" }
    }

    func setAssetIdentifiers(_ ids: [String]) {
        assetIdentifiersCSV = ids.joined(separator: ",")
    }

    func setYearAnswers(_ answers: [Bool]) {
        yearAnswersCSV = answers.map { $0 ? "1" : "0" }.joined(separator: ",")
    }

    func toCoreState() -> DailyChallengeState {
        let answers = yearAnswers
        let status: DailyChallengeStatus
        if isCompleted {
            status = .completed(score: MemoryScore(correctCount: scoreCorrectCount))
        } else if answers.isEmpty {
            status = .notStarted
        } else {
            status = .inProgress(answeredCount: answers.count)
        }
        return DailyChallengeState(
            challengeDate: challengeDay,
            status: status,
            assetIdentifiers: assetIdentifiers,
            yearAnswersCorrect: answers,
            bonusMonthCorrectCount: bonusMonthCorrectCount
        )
    }
}

enum PersistenceController {
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([StreakRecord.self, DailyChallengeRecord.self])
        let configuration = ModelConfiguration(
            isStoredInMemoryOnly: inMemory
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
