import Foundation

/// Calendar-day helpers. Never use raw 24-hour deltas for daily boundaries.
public enum DateLogic {
    public static func startOfDay(_ date: Date, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: date)
    }

    public static func isSameDay(_ lhs: Date, _ rhs: Date, calendar: Calendar = .current) -> Bool {
        calendar.isDate(lhs, inSameDayAs: rhs)
    }

    /// Returns true when `candidate` is exactly one calendar day before `reference`.
    public static func isYesterday(
        candidate: Date,
        relativeTo reference: Date,
        calendar: Calendar = .current
    ) -> Bool {
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: startOfDay(reference, calendar: calendar)) else {
            return false
        }
        return isSameDay(candidate, yesterday, calendar: calendar)
    }

    public static func yearsAgo(from creationDate: Date, to reference: Date = Date(), calendar: Calendar = .current) -> Int {
        calendar.dateComponents([.year], from: creationDate, to: reference).year ?? 0
    }

    public static func year(of date: Date, calendar: Calendar = .current) -> Int {
        calendar.component(.year, from: date)
    }

    public static func month(of date: Date, calendar: Calendar = .current) -> Int {
        calendar.component(.month, from: date)
    }

    public static func day(of date: Date, calendar: Calendar = .current) -> Int {
        calendar.component(.day, from: date)
    }
}
