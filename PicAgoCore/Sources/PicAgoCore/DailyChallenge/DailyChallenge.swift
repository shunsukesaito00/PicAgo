import Foundation

public enum DailyChallengeStatus: Equatable, Sendable {
    case notStarted
    case inProgress(answeredCount: Int)
    case completed(score: MemoryScore)
}

public struct DailyChallengeState: Equatable, Sendable {
    public static let questionsPerDay = 5

    public var challengeDate: Date
    public var status: DailyChallengeStatus
    public var assetIdentifiers: [String]
    public var yearAnswersCorrect: [Bool]
    public var bonusMonthCorrectCount: Int

    public init(
        challengeDate: Date,
        status: DailyChallengeStatus = .notStarted,
        assetIdentifiers: [String] = [],
        yearAnswersCorrect: [Bool] = [],
        bonusMonthCorrectCount: Int = 0
    ) {
        self.challengeDate = DateLogic.startOfDay(challengeDate)
        self.status = status
        self.assetIdentifiers = assetIdentifiers
        self.yearAnswersCorrect = yearAnswersCorrect
        self.bonusMonthCorrectCount = bonusMonthCorrectCount
    }

    public var isCompletedToday: Bool {
        if case .completed = status { return true }
        return false
    }
}

public enum DailyChallengeEngine {
    public static func isToday(
        _ challengeDate: Date,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        DateLogic.isSameDay(challengeDate, now, calendar: calendar)
    }

    public static func homePresentation(
        state: DailyChallengeState?,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> HomeDailyPresentation {
        guard let state, isToday(state.challengeDate, now: now, calendar: calendar) else {
            return .readyToPlay
        }
        switch state.status {
        case .notStarted:
            return .readyToPlay
        case .inProgress(let answered):
            return .inProgress(answeredCount: answered)
        case .completed(let score):
            return .todayComplete(score: score)
        }
    }

    public static func recordYearAnswer(
        state: inout DailyChallengeState,
        correct: Bool
    ) {
        state.yearAnswersCorrect.append(correct)
        let count = state.yearAnswersCorrect.count
        if count >= DailyChallengeState.questionsPerDay {
            let score = Scoring.score(answers: state.yearAnswersCorrect)
            state.status = .completed(score: score)
        } else {
            state.status = .inProgress(answeredCount: count)
        }
    }

    /// DEBUG / developer menu only — production UI must not expose this.
    public static func resetForDeveloper(_ state: DailyChallengeState, on date: Date = Date()) -> DailyChallengeState {
        DailyChallengeState(challengeDate: date)
    }
}

public enum HomeDailyPresentation: Equatable, Sendable {
    case readyToPlay
    case inProgress(answeredCount: Int)
    case todayComplete(score: MemoryScore)
}
