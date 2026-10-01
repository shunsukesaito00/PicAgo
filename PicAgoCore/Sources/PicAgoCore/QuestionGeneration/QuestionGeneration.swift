import Foundation

public struct YearChoices: Equatable, Sendable {
    public let choices: [Int]
    public let correctYear: Int

    public init(choices: [Int], correctYear: Int) {
        self.choices = choices
        self.correctYear = correctYear
    }

    public var isValid: Bool {
        Set(choices).count == 4
            && choices.count == 4
            && choices.contains(correctYear)
    }
}

public struct MonthChoices: Equatable, Sendable {
    public let choices: [Int]
    public let correctMonth: Int

    public init(choices: [Int], correctMonth: Int) {
        self.choices = choices
        self.correctMonth = correctMonth
    }

    public var isValid: Bool {
        Set(choices).count == 4
            && choices.count == 4
            && choices.contains(correctMonth)
            && choices.allSatisfy { (1...12).contains($0) }
    }
}

public struct GeneratedQuestion: Equatable, Sendable {
    public let assetIdentifier: String
    public let creationDate: Date
    public let yearChoices: YearChoices
    public let includesBonusMonth: Bool
    public let monthChoices: MonthChoices?

    public init(
        assetIdentifier: String,
        creationDate: Date,
        yearChoices: YearChoices,
        includesBonusMonth: Bool,
        monthChoices: MonthChoices?
    ) {
        self.assetIdentifier = assetIdentifier
        self.creationDate = creationDate
        self.yearChoices = yearChoices
        self.includesBonusMonth = includesBonusMonth
        self.monthChoices = monthChoices
    }
}

public struct PhotoCandidate: Equatable, Sendable {
    public let assetIdentifier: String
    public let creationDate: Date

    public init(assetIdentifier: String, creationDate: Date) {
        self.assetIdentifier = assetIdentifier
        self.creationDate = creationDate
    }
}

public enum QuestionGeneration {
    public static let questionsPerChallenge = 5
    public static let maxBonusMonthQuestions = 2

    /// Build 4 distinct year choices clustered around the correct year.
    /// Prefer years that exist in the library when available.
    public static func makeYearChoices(
        correctYear: Int,
        libraryYears: [Int] = [],
        currentYear: Int = Calendar.current.component(.year, from: Date()),
        randomSource: (ClosedRange<Int>) -> Int = { Int.random(in: $0) }
    ) -> YearChoices {
        var selected: Set<Int> = [correctYear]
        let availableLibrary = Set(libraryYears.filter { $0 != correctYear && $0 <= currentYear && $0 >= 1990 })

        // Prefer nearby library years (±1…3 first, then slightly wider).
        let nearbyOffsets = [1, -1, 2, -2, 3, -3, 4, -4, 5, -5]
        for offset in nearbyOffsets {
            guard selected.count < 4 else { break }
            let candidate = correctYear + offset
            if availableLibrary.contains(candidate) {
                selected.insert(candidate)
            }
        }

        // Fill with adjacent years even if not in library (keeps difficulty fair).
        for offset in nearbyOffsets {
            guard selected.count < 4 else { break }
            let candidate = correctYear + offset
            if candidate >= 1990 && candidate <= currentYear {
                selected.insert(candidate)
            }
        }

        // Narrow library edge case: walk outward until we have 4 unique years.
        var step = 1
        while selected.count < 4 && step < 80 {
            let up = correctYear + step
            let down = correctYear - step
            if up <= currentYear + 1 { selected.insert(min(up, currentYear)) }
            if down >= 1990 { selected.insert(down) }
            step += 1
            if selected.count >= 4 { break }
        }

        // Absolute fallback (should be unreachable for sane inputs).
        var filler = max(1990, correctYear - 10)
        while selected.count < 4 {
            if filler != correctYear && filler <= currentYear {
                selected.insert(filler)
            }
            filler += 1
            if filler > currentYear + 20 { break }
        }

        var choices = Array(selected.prefix(4))
        // Ensure correct year is present and length is exactly 4.
        if !choices.contains(correctYear) {
            choices[0] = correctYear
        }
        while choices.count < 4 {
            let extra = correctYear + choices.count
            if !choices.contains(extra) { choices.append(extra) }
            else { choices.append(correctYear - choices.count) }
        }
        choices = Array(Set(choices).prefix(4))
        if choices.count < 4 || !choices.contains(correctYear) {
            choices = rebuildCluster(correctYear: correctYear, currentYear: currentYear)
        }

        // Light shuffle without depending on GameKit.
        choices = shuffle(choices, randomSource: randomSource)
        return YearChoices(choices: choices, correctYear: correctYear)
    }

    public static func makeMonthChoices(
        correctMonth: Int,
        randomSource: (ClosedRange<Int>) -> Int = { Int.random(in: $0) }
    ) -> MonthChoices {
        precondition((1...12).contains(correctMonth))
        var selected: Set<Int> = [correctMonth]
        let offsets = [1, -1, 2, -2, 3, -3, 4, -4, 5, -5, 6]
        for offset in offsets {
            guard selected.count < 4 else { break }
            var month = correctMonth + offset
            if month < 1 { month += 12 }
            if month > 12 { month -= 12 }
            selected.insert(month)
        }
        var choices = Array(selected)
        while choices.count < 4 {
            let m = randomSource(1...12)
            if !choices.contains(m) { choices.append(m) }
        }
        choices = Array(choices.prefix(4))
        choices = shuffle(choices, randomSource: randomSource)
        return MonthChoices(choices: choices, correctMonth: correctMonth)
    }

    /// Select up to 5 photos for a daily challenge, avoiding ID duplicates and
    /// preferring to skip near-burst neighbors (creation dates within 30s).
    public static func selectPhotos(
        from candidates: [PhotoCandidate],
        count: Int = questionsPerChallenge,
        randomSource: (ClosedRange<Int>) -> Int = { Int.random(in: $0) }
    ) -> [PhotoCandidate] {
        let valid = candidates.filter { $0.creationDate.timeIntervalSince1970 > 0 }
        guard !valid.isEmpty else { return [] }

        var pool = valid
        // Fisher-Yates shuffle
        if pool.count > 1 {
            for i in stride(from: pool.count - 1, through: 1, by: -1) {
                let j = randomSource(0...i)
                pool.swapAt(i, j)
            }
        }

        var selected: [PhotoCandidate] = []
        var usedIDs = Set<String>()

        for candidate in pool {
            if selected.count >= count { break }
            if usedIDs.contains(candidate.assetIdentifier) { continue }
            if let last = selected.last,
               abs(last.creationDate.timeIntervalSince(candidate.creationDate)) < 30 {
                continue
            }
            selected.append(candidate)
            usedIDs.insert(candidate.assetIdentifier)
        }

        // If burst avoidance left us short, fill remaining without the burst rule.
        if selected.count < count {
            for candidate in pool {
                if selected.count >= count { break }
                if usedIDs.contains(candidate.assetIdentifier) { continue }
                selected.append(candidate)
                usedIDs.insert(candidate.assetIdentifier)
            }
        }

        return selected
    }

    public static func generateChallenge(
        candidates: [PhotoCandidate],
        bonusMonthEnabled: Bool,
        libraryYears: [Int]? = nil,
        now: Date = Date(),
        calendar: Calendar = .current,
        randomSource: (ClosedRange<Int>) -> Int = { Int.random(in: $0) }
    ) -> [GeneratedQuestion] {
        let photos = selectPhotos(from: candidates, count: questionsPerChallenge, randomSource: randomSource)
        let years = libraryYears ?? Array(Set(candidates.map { DateLogic.year(of: $0.creationDate, calendar: calendar) }))
        let currentYear = DateLogic.year(of: now, calendar: calendar)

        var bonusSlots = Set<Int>()
        if bonusMonthEnabled && photos.count >= 1 {
            let bonusCount = min(maxBonusMonthQuestions, max(1, photos.count / 3 + (randomSource(0...1))))
            while bonusSlots.count < min(bonusCount, photos.count) {
                bonusSlots.insert(randomSource(0...(photos.count - 1)))
            }
        }

        return photos.enumerated().map { index, photo in
            let year = DateLogic.year(of: photo.creationDate, calendar: calendar)
            let yearChoices = makeYearChoices(
                correctYear: year,
                libraryYears: years,
                currentYear: currentYear,
                randomSource: randomSource
            )
            let includeBonus = bonusSlots.contains(index)
            let monthChoices: MonthChoices? = includeBonus
                ? makeMonthChoices(
                    correctMonth: DateLogic.month(of: photo.creationDate, calendar: calendar),
                    randomSource: randomSource
                )
                : nil
            return GeneratedQuestion(
                assetIdentifier: photo.assetIdentifier,
                creationDate: photo.creationDate,
                yearChoices: yearChoices,
                includesBonusMonth: includeBonus,
                monthChoices: monthChoices
            )
        }
    }

    // MARK: - Private helpers

    private static func rebuildCluster(correctYear: Int, currentYear: Int) -> [Int] {
        var result: [Int] = [correctYear]
        for offset in [1, -1, 2, -2, 3, -3, 4, -4] {
            let y = correctYear + offset
            if y >= 1990 && y <= max(currentYear, correctYear) && !result.contains(y) {
                result.append(y)
            }
            if result.count == 4 { break }
        }
        var filler = correctYear + 5
        while result.count < 4 {
            if !result.contains(filler) { result.append(filler) }
            filler += 1
        }
        return Array(result.prefix(4))
    }

    private static func shuffle(_ values: [Int], randomSource: (ClosedRange<Int>) -> Int) -> [Int] {
        var array = values
        guard array.count > 1 else { return array }
        for i in stride(from: array.count - 1, through: 1, by: -1) {
            let j = randomSource(0...i)
            array.swapAt(i, j)
        }
        return array
    }
}
