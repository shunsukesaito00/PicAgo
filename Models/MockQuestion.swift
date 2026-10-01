import Foundation
import PicAgoCore

enum MockQuestion {
    static func sample(
        year: Int = 2019,
        includeBonus: Bool = false
    ) -> GameQuestion {
        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(from: DateComponents(year: year, month: 6, day: 15)) ?? Date()
        let years = QuestionGeneration.makeYearChoices(
            correctYear: year,
            libraryYears: [year - 1, year, year + 1, year + 2],
            currentYear: 2026,
            randomSource: { $0.lowerBound }
        )
        let months: MonthChoices? = includeBonus
            ? QuestionGeneration.makeMonthChoices(correctMonth: 6, randomSource: { $0.lowerBound })
            : nil
        return GameQuestion(
            id: "mock-q-\(year)",
            assetIdentifier: "mock-asset-\(year)",
            creationDate: date,
            yearChoices: years.choices,
            correctYear: year,
            includesBonusMonth: includeBonus,
            monthChoices: months?.choices,
            correctMonth: months?.correctMonth
        )
    }

    static func dailySet() -> [GameQuestion] {
        [2016, 2018, 2019, 2021, 2023].enumerated().map { index, year in
            sample(year: year, includeBonus: index == 1)
        }
    }
}
