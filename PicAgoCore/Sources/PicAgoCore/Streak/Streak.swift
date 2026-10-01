import Foundation

public struct StreakState: Equatable, Sendable {
    public var currentStreak: Int
    public var longestStreak: Int
    public var lastCompletedDate: Date?
    public var bestScore: Int
    public var yesterdayScore: Int?
    public var todayScore: Int?

    public init(
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
}

public enum StreakEngine {
    /// Apply a completed daily challenge. Same-day recompute does not increase streak.
    public static func applyCompletion(
        to state: StreakState,
        score: Int,
        on date: Date,
        calendar: Calendar = .current
    ) -> StreakState {
        var next = state
        let day = DateLogic.startOfDay(date, calendar: calendar)

        if let last = state.lastCompletedDate,
           DateLogic.isSameDay(last, day, calendar: calendar) {
            // Same day: update today's score / best, do not bump streak.
            next.todayScore = score
            next.bestScore = max(state.bestScore, score)
            return next
        }

        if let last = state.lastCompletedDate,
           DateLogic.isYesterday(candidate: last, relativeTo: day, calendar: calendar) {
            next.currentStreak = state.currentStreak + 1
            next.yesterdayScore = state.todayScore
        } else {
            next.currentStreak = 1
            next.yesterdayScore = nil
        }

        next.todayScore = score
        next.lastCompletedDate = day
        next.bestScore = max(state.bestScore, score)
        next.longestStreak = max(state.longestStreak, next.currentStreak)
        return next
    }
}
