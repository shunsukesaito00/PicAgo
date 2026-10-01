import Foundation
import SwiftData
import SwiftUI
import PicAgoCore
#if canImport(UIKit)
import UIKit
#endif

@MainActor
@Observable
final class GameViewModel {
    enum Phase: Equatable {
        case loading
        case empty
        case answeringYear
        case revealingYear(correct: Bool, selected: Int)
        case answeringMonth
        case revealingMonth(correct: Bool, selected: Int)
        case finished
    }

    private let session: AppSession
    private let modelContext: ModelContext

    var phase: Phase = .loading
    var questions: [GameQuestion] = []
    var index: Int = 0
    var yearResults: [Bool] = []
    var bonusCorrectCount: Int = 0
    var currentImage: PlatformImage?
    var loadErrorSoft = false

    var current: GameQuestion? {
        guard questions.indices.contains(index) else { return nil }
        return questions[index]
    }

    var progressLabel: String {
        "\(index + 1)/\(max(questions.count, 1))"
    }

    init(session: AppSession, modelContext: ModelContext) {
        self.session = session
        self.modelContext = modelContext
    }

    func start() async {
        phase = .loading
        currentImage = nil
        let assets = await session.photoLibrary.fetchEligibleAssets()
        guard assets.count >= 4 else {
            phase = .empty
            return
        }

        let candidates = assets.map {
            PhotoCandidate(assetIdentifier: $0.assetIdentifier, creationDate: $0.creationDate)
        }
        let libraryYears = Array(Set(candidates.map { DateLogic.year(of: $0.creationDate) }))
        let generated = QuestionGeneration.generateChallenge(
            candidates: candidates,
            bonusMonthEnabled: FeatureFlags.bonusMonthQuestionsEnabled,
            libraryYears: libraryYears
        )
        questions = generated.map(GameQuestion.init(from:))
        yearResults = []
        bonusCorrectCount = 0
        index = 0

        guard !questions.isEmpty else {
            phase = .empty
            return
        }

        persistChallengeStart()
        phase = .answeringYear
        await loadCurrentImage()
    }

    func selectYear(_ year: Int) {
        guard phase == .answeringYear, let current else { return }
        let correct = year == current.correctYear
        yearResults.append(correct)
        phase = .revealingYear(correct: correct, selected: year)
        triggerHaptic(success: correct)

        if correct,
           current.includesBonusMonth,
           FeatureFlags.bonusMonthQuestionsEnabled,
           current.monthChoices != nil {
            // Stay on reveal; Continue moves to month.
        }
    }

    func continueAfterYearReveal() {
        guard case .revealingYear(let correct, _) = phase, let current else { return }
        if correct,
           current.includesBonusMonth,
           FeatureFlags.bonusMonthQuestionsEnabled,
           current.monthChoices != nil {
            phase = .answeringMonth
        } else {
            advanceOrFinish()
        }
    }

    func selectMonth(_ month: Int) {
        guard phase == .answeringMonth, let current, let correctMonth = current.correctMonth else { return }
        let correct = month == correctMonth
        if correct { bonusCorrectCount += 1 }
        phase = .revealingMonth(correct: correct, selected: month)
        triggerHaptic(success: correct)
    }

    func continueAfterMonthReveal() {
        advanceOrFinish()
    }

    private func advanceOrFinish() {
        if index + 1 >= questions.count {
            finishChallenge()
        } else {
            index += 1
            phase = .answeringYear
            currentImage = nil
            Task { await loadCurrentImage() }
        }
    }

    private func finishChallenge() {
        phase = .finished
        let score = Scoring.score(answers: yearResults)
        persistCompletion(score: score)

        let streakRecord = loadOrCreateStreak()
        let next = StreakEngine.applyCompletion(to: streakRecord.asState(), score: score.correctCount, on: Date())
        streakRecord.apply(next)
        try? modelContext.save()

        let share = SharePayload(score: score, streak: next.currentStreak, results: yearResults)
        session.showResult(share: share, bonusCorrect: bonusCorrectCount)
    }

    private func loadCurrentImage() async {
        guard let current else { return }
        #if canImport(UIKit)
        let size = CGSize(width: 900, height: 1200)
        #else
        let size = CGSize(width: 300, height: 400)
        #endif
        currentImage = await session.photoLibrary.requestImage(
            for: current.assetIdentifier,
            targetSize: size
        )
        loadErrorSoft = currentImage == nil
    }

    private func persistChallengeStart() {
        let today = DateLogic.startOfDay(Date())
        let record = loadOrCreateToday(day: today)
        record.setAssetIdentifiers(questions.map(\.assetIdentifier))
        record.setYearAnswers([])
        record.isCompleted = false
        record.bonusMonthCorrectCount = 0
        try? modelContext.save()
    }

    private func persistCompletion(score: MemoryScore) {
        let today = DateLogic.startOfDay(Date())
        let record = loadOrCreateToday(day: today)
        record.setYearAnswers(yearResults)
        record.isCompleted = true
        record.scoreCorrectCount = score.correctCount
        record.bonusMonthCorrectCount = bonusCorrectCount
        try? modelContext.save()
    }

    private func loadOrCreateToday(day: Date) -> DailyChallengeRecord {
        let descriptor = FetchDescriptor<DailyChallengeRecord>(
            predicate: #Predicate { $0.challengeDay == day }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        let created = DailyChallengeRecord(challengeDay: day)
        modelContext.insert(created)
        return created
    }

    private func loadOrCreateStreak() -> StreakRecord {
        var descriptor = FetchDescriptor<StreakRecord>()
        descriptor.fetchLimit = 1
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        let created = StreakRecord()
        modelContext.insert(created)
        return created
    }

    private func triggerHaptic(success: Bool) {
        #if canImport(UIKit)
        if success {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
        #endif
    }
}
