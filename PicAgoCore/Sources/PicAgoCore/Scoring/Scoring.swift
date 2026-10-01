import Foundation

/// Simple Daily Memory scoring: 1 point per correct year answer, max 5.
public struct MemoryScore: Equatable, Sendable {
    public let correctCount: Int
    public let totalQuestions: Int

    public init(correctCount: Int, totalQuestions: Int = 5) {
        self.correctCount = max(0, min(correctCount, totalQuestions))
        self.totalQuestions = max(1, totalQuestions)
    }

    public var percentage: Int {
        Int((Double(correctCount) / Double(totalQuestions) * 100.0).rounded())
    }

    public var isPerfect: Bool {
        correctCount == totalQuestions
    }

    public var displayFraction: String {
        "\(correctCount)/\(totalQuestions)"
    }
}

public enum Scoring {
    public static func score(answers: [Bool], totalQuestions: Int = 5) -> MemoryScore {
        let limited = Array(answers.prefix(totalQuestions))
        let correct = limited.filter { $0 }.count
        return MemoryScore(correctCount: correct, totalQuestions: totalQuestions)
    }

    public static func score(correctCount: Int, totalQuestions: Int = 5) -> MemoryScore {
        MemoryScore(correctCount: correctCount, totalQuestions: totalQuestions)
    }
}
