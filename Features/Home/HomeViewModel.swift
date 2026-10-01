import Foundation
import SwiftData
import SwiftUI
import PicAgoCore

@MainActor
@Observable
final class HomeViewModel {
    private let session: AppSession
    private let modelContext: ModelContext

    var presentation: HomeDailyPresentation = .readyToPlay
    var streak: StreakState = StreakState()
    var eligibleCount: Int = 0
    var authorization: PhotoAuthorizationState = .notDetermined
    var isLoading = false

    init(session: AppSession, modelContext: ModelContext) {
        self.session = session
        self.modelContext = modelContext
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        session.photoLibrary.refreshAuthorizationState()
        authorization = session.photoLibrary.authorizationState

        let assets = await session.photoLibrary.fetchEligibleAssets()
        eligibleCount = assets.count

        streak = loadOrCreateStreak().asState()
        let daily = loadTodayRecord()?.toCoreState()
        presentation = DailyChallengeEngine.homePresentation(state: daily)
    }

    var canPlay: Bool {
        switch authorization {
        case .authorized, .limited:
            return eligibleCount >= 4 && !isCompletedToday
        case .denied, .restricted, .notDetermined:
            return false
        }
    }

    var isCompletedToday: Bool {
        if case .todayComplete = presentation { return true }
        return false
    }

    var needsPermission: Bool {
        switch authorization {
        case .denied, .restricted, .notDetermined:
            return true
        case .authorized, .limited:
            return false
        }
    }

    var tooFewPhotos: Bool {
        (authorization == .authorized || authorization == .limited) && eligibleCount < 4
    }

    func play() {
        guard canPlay else { return }
        session.startGame()
    }

    func requestPermission() async {
        _ = await session.photoLibrary.requestAuthorization()
        await refresh()
    }

    func openSettings() {
        session.photoLibrary.openSystemSettings()
    }

    #if DEBUG
    func developerResetToday() throws {
        if let record = loadTodayRecord() {
            modelContext.delete(record)
            try modelContext.save()
        }
        Task { await refresh() }
    }
    #endif

    private func loadOrCreateStreak() -> StreakRecord {
        var descriptor = FetchDescriptor<StreakRecord>()
        descriptor.fetchLimit = 1
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        let created = StreakRecord()
        modelContext.insert(created)
        try? modelContext.save()
        return created
    }

    private func loadTodayRecord() -> DailyChallengeRecord? {
        let today = DateLogic.startOfDay(Date())
        let descriptor = FetchDescriptor<DailyChallengeRecord>(
            predicate: #Predicate { $0.challengeDay == today }
        )
        return try? modelContext.fetch(descriptor).first
    }
}
