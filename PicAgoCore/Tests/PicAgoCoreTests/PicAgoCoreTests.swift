import XCTest
@testable import PicAgoCore
import Foundation

final class QuestionGenerationTests: XCTestCase {
    func testYearChoicesContainCorrectYear() {
        let choices = QuestionGeneration.makeYearChoices(
            correctYear: 2019,
            libraryYears: [2015, 2018, 2019, 2020, 2021],
            currentYear: 2026,
            randomSource: deterministicRandom([0, 1, 0, 1, 0, 1, 0, 1])
        )
        XCTAssertTrue(choices.choices.contains(2019))
        XCTAssertEqual(choices.correctYear, 2019)
    }

    func testYearChoicesAreFourDistinct() {
        let choices = QuestionGeneration.makeYearChoices(
            correctYear: 2020,
            libraryYears: [2020],
            currentYear: 2026,
            randomSource: { $0.lowerBound }
        )
        XCTAssertEqual(choices.choices.count, 4)
        XCTAssertEqual(Set(choices.choices).count, 4)
        XCTAssertTrue(choices.isValid)
    }

    func testYearChoicesNoDuplicates() {
        let choices = QuestionGeneration.makeYearChoices(
            correctYear: 2015,
            libraryYears: [2015, 2015, 2016],
            currentYear: 2026,
            randomSource: { $0.lowerBound }
        )
        XCTAssertEqual(Set(choices.choices).count, choices.choices.count)
    }

    func testYearChoicesNarrowRangeStillWorks() {
        // Brand-new library with only one year available.
        let choices = QuestionGeneration.makeYearChoices(
            correctYear: 2026,
            libraryYears: [2026],
            currentYear: 2026,
            randomSource: { $0.lowerBound }
        )
        XCTAssertTrue(choices.isValid)
        XCTAssertTrue(choices.choices.contains(2026))
        // Should stay clustered, not jump to distant decades.
        let span = (choices.choices.max() ?? 0) - (choices.choices.min() ?? 0)
        XCTAssertLessThanOrEqual(span, 8)
    }

    func testYearChoicesPreferNearbyOverDistant() {
        let choices = QuestionGeneration.makeYearChoices(
            correctYear: 2018,
            libraryYears: [2008, 2014, 2017, 2018, 2019, 2022, 2026],
            currentYear: 2026,
            randomSource: { $0.lowerBound }
        )
        // Nearby library years 2017/2019 should be preferred over 2008/2026 gaps.
        XCTAssertTrue(choices.choices.contains(2017) || choices.choices.contains(2019))
        let averageDistance = choices.choices
            .map { abs($0 - 2018) }
            .reduce(0, +) / choices.choices.count
        XCTAssertLessThanOrEqual(averageDistance, 3)
    }

    func testMonthChoicesValid() {
        let months = QuestionGeneration.makeMonthChoices(
            correctMonth: 7,
            randomSource: { $0.lowerBound }
        )
        XCTAssertTrue(months.isValid)
        XCTAssertEqual(months.correctMonth, 7)
    }

    func testSelectPhotosAvoidsDuplicates() {
        let calendar = Calendar(identifier: .gregorian)
        var comps = DateComponents(year: 2020, month: 1, day: 1)
        let d1 = calendar.date(from: comps)!
        comps.day = 2
        let d2 = calendar.date(from: comps)!
        comps.day = 3
        let d3 = calendar.date(from: comps)!
        let candidates = [
            PhotoCandidate(assetIdentifier: "a", creationDate: d1),
            PhotoCandidate(assetIdentifier: "a", creationDate: d1),
            PhotoCandidate(assetIdentifier: "b", creationDate: d2),
            PhotoCandidate(assetIdentifier: "c", creationDate: d3)
        ]
        let selected = QuestionGeneration.selectPhotos(
            from: candidates,
            count: 3,
            randomSource: { $0.lowerBound }
        )
        XCTAssertEqual(Set(selected.map(\.assetIdentifier)).count, selected.count)
        XCTAssertLessThanOrEqual(selected.count, 3)
    }

    func testGenerateChallengeRespectsBonusFlagOff() {
        let photos = samplePhotos(count: 5)
        let questions = QuestionGeneration.generateChallenge(
            candidates: photos,
            bonusMonthEnabled: false,
            now: fixedNow(),
            calendar: testCalendar(),
            randomSource: { $0.lowerBound }
        )
        XCTAssertEqual(questions.count, 5)
        XCTAssertTrue(questions.allSatisfy { !$0.includesBonusMonth })
        XCTAssertTrue(questions.allSatisfy { $0.monthChoices == nil })
    }

    func testGenerateChallengeBonusLimited() {
        let photos = samplePhotos(count: 5)
        let questions = QuestionGeneration.generateChallenge(
            candidates: photos,
            bonusMonthEnabled: true,
            now: fixedNow(),
            calendar: testCalendar(),
            randomSource: deterministicRandom([0, 1, 0, 1, 2, 0, 1, 0, 1, 0])
        )
        let bonusCount = questions.filter(\.includesBonusMonth).count
        XCTAssertLessThanOrEqual(bonusCount, QuestionGeneration.maxBonusMonthQuestions)
    }

    // MARK: - Helpers

    private func samplePhotos(count: Int) -> [PhotoCandidate] {
        let calendar = testCalendar()
        return (0..<count).compactMap { i in
            var c = DateComponents()
            c.year = 2018 + (i % 5)
            c.month = (i % 12) + 1
            c.day = 10
            c.hour = i
            guard let date = calendar.date(from: c) else { return nil }
            return PhotoCandidate(assetIdentifier: "id-\(i)", creationDate: date)
        }
    }

    private func testCalendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func fixedNow() -> Date {
        var c = DateComponents()
        c.year = 2026
        c.month = 10
        c.day = 1
        return testCalendar().date(from: c)!
    }

    private func deterministicRandom(_ sequence: [Int]) -> (ClosedRange<Int>) -> Int {
        var index = 0
        return { range in
            defer { index += 1 }
            let value = sequence[index % sequence.count]
            let span = range.upperBound - range.lowerBound
            if span == 0 { return range.lowerBound }
            return range.lowerBound + abs(value) % (span + 1)
        }
    }
}

final class ScoringTests: XCTestCase {
    func testScoreBasic() {
        let score = Scoring.score(answers: [true, true, false, true, false])
        XCTAssertEqual(score.correctCount, 3)
        XCTAssertEqual(score.percentage, 60)
        XCTAssertEqual(score.displayFraction, "3/5")
        XCTAssertFalse(score.isPerfect)
    }

    func testPerfectScore() {
        let score = Scoring.score(correctCount: 5)
        XCTAssertTrue(score.isPerfect)
        XCTAssertEqual(score.percentage, 100)
    }

    func testZeroScore() {
        let score = Scoring.score(answers: [false, false, false, false, false])
        XCTAssertEqual(score.correctCount, 0)
        XCTAssertEqual(score.percentage, 0)
    }

    func testScoreClamped() {
        let score = Scoring.score(correctCount: 99)
        XCTAssertEqual(score.correctCount, 5)
    }
}

final class StreakTests: XCTestCase {
    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }()

    private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d))!
    }

    func testFirstCompletionStartsStreakAtOne() {
        let state = StreakState()
        let next = StreakEngine.applyCompletion(to: state, score: 4, on: day(2026, 10, 1), calendar: calendar)
        XCTAssertEqual(next.currentStreak, 1)
        XCTAssertEqual(next.longestStreak, 1)
        XCTAssertEqual(next.todayScore, 4)
        XCTAssertEqual(next.bestScore, 4)
    }

    func testYesterdayCompletionIncrements() {
        var state = StreakState(currentStreak: 3, longestStreak: 5, lastCompletedDate: day(2026, 9, 30), todayScore: 3)
        state = StreakEngine.applyCompletion(to: state, score: 5, on: day(2026, 10, 1), calendar: calendar)
        XCTAssertEqual(state.currentStreak, 4)
        XCTAssertEqual(state.longestStreak, 5)
        XCTAssertEqual(state.yesterdayScore, 3)
    }

    func testMissedDayResetsToOne() {
        let state = StreakState(currentStreak: 10, longestStreak: 10, lastCompletedDate: day(2026, 9, 28))
        let next = StreakEngine.applyCompletion(to: state, score: 2, on: day(2026, 10, 1), calendar: calendar)
        XCTAssertEqual(next.currentStreak, 1)
        XCTAssertEqual(next.longestStreak, 10)
    }

    func testSameDayDoesNotIncrement() {
        let state = StreakState(
            currentStreak: 2,
            longestStreak: 2,
            lastCompletedDate: day(2026, 10, 1),
            bestScore: 3,
            todayScore: 3
        )
        let next = StreakEngine.applyCompletion(to: state, score: 5, on: day(2026, 10, 1), calendar: calendar)
        XCTAssertEqual(next.currentStreak, 2)
        XCTAssertEqual(next.todayScore, 5)
        XCTAssertEqual(next.bestScore, 5)
    }

    func testLongestStreakUpdates() {
        let state = StreakState(currentStreak: 5, longestStreak: 5, lastCompletedDate: day(2026, 9, 30))
        let next = StreakEngine.applyCompletion(to: state, score: 1, on: day(2026, 10, 1), calendar: calendar)
        XCTAssertEqual(next.currentStreak, 6)
        XCTAssertEqual(next.longestStreak, 6)
    }
}

final class DateLogicTests: XCTestCase {
    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }()

    func testSameDayAcrossHours() {
        let morning = calendar.date(from: DateComponents(year: 2026, month: 10, day: 1, hour: 1))!
        let night = calendar.date(from: DateComponents(year: 2026, month: 10, day: 1, hour: 23))!
        XCTAssertTrue(DateLogic.isSameDay(morning, night, calendar: calendar))
    }

    func testDayBoundaryNotSameDay() {
        let late = calendar.date(from: DateComponents(year: 2026, month: 10, day: 1, hour: 23, minute: 59))!
        let early = calendar.date(from: DateComponents(year: 2026, month: 10, day: 2, hour: 0, minute: 1))!
        XCTAssertFalse(DateLogic.isSameDay(late, early, calendar: calendar))
        // 24h-ish gap but different calendar days — must NOT treat as same.
        XCTAssertTrue(DateLogic.isYesterday(candidate: late, relativeTo: early, calendar: calendar))
    }

    func testIsYesterday() {
        let today = calendar.date(from: DateComponents(year: 2026, month: 10, day: 1))!
        let yesterday = calendar.date(from: DateComponents(year: 2026, month: 9, day: 30))!
        let twoDaysAgo = calendar.date(from: DateComponents(year: 2026, month: 9, day: 29))!
        XCTAssertTrue(DateLogic.isYesterday(candidate: yesterday, relativeTo: today, calendar: calendar))
        XCTAssertFalse(DateLogic.isYesterday(candidate: twoDaysAgo, relativeTo: today, calendar: calendar))
    }

    func testYearsAgo() {
        let created = calendar.date(from: DateComponents(year: 2021, month: 10, day: 1))!
        let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 1))!
        XCTAssertEqual(DateLogic.yearsAgo(from: created, to: now, calendar: calendar), 5)
    }
}

final class DailyChallengeTests: XCTestCase {
    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }()

    private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d))!
    }

    func testHomeReadyWhenNoState() {
        let presentation = DailyChallengeEngine.homePresentation(state: nil, now: day(2026, 10, 1), calendar: calendar)
        XCTAssertEqual(presentation, .readyToPlay)
    }

    func testHomeCompleteShowsScore() {
        let score = MemoryScore(correctCount: 4)
        let state = DailyChallengeState(
            challengeDate: day(2026, 10, 1),
            status: .completed(score: score)
        )
        let presentation = DailyChallengeEngine.homePresentation(
            state: state,
            now: day(2026, 10, 1),
            calendar: calendar
        )
        XCTAssertEqual(presentation, .todayComplete(score: score))
    }

    func testYesterdayStateIsReadyToday() {
        let state = DailyChallengeState(
            challengeDate: day(2026, 9, 30),
            status: .completed(score: MemoryScore(correctCount: 5))
        )
        let presentation = DailyChallengeEngine.homePresentation(
            state: state,
            now: day(2026, 10, 1),
            calendar: calendar
        )
        XCTAssertEqual(presentation, .readyToPlay)
    }

    func testRecordAnswersCompletesAtFive() {
        var state = DailyChallengeState(challengeDate: day(2026, 10, 1))
        for i in 0..<5 {
            DailyChallengeEngine.recordYearAnswer(state: &state, correct: i % 2 == 0)
        }
        guard case .completed(let score) = state.status else {
            return XCTFail("Expected completed")
        }
        XCTAssertEqual(score.correctCount, 3)
    }

    func testDeveloperReset() {
        let state = DailyChallengeState(
            challengeDate: day(2026, 10, 1),
            status: .completed(score: MemoryScore(correctCount: 5)),
            yearAnswersCorrect: [true, true, true, true, true]
        )
        let reset = DailyChallengeEngine.resetForDeveloper(state, on: day(2026, 10, 1))
        XCTAssertEqual(reset.status, .notStarted)
        XCTAssertTrue(reset.yearAnswersCorrect.isEmpty)
    }
}
