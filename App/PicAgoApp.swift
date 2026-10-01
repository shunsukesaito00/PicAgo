import SwiftUI
import SwiftData

@main
struct PicAgoApp: App {
    private let container: ModelContainer
    @State private var session: AppSession

    init() {
        let modelContainer = Self.makeContainer()
        self.container = modelContainer

        #if canImport(Photos) && canImport(UIKit)
        let library: any PhotoLibraryServing = PhotoLibraryService()
        #else
        let library: any PhotoLibraryServing = MockPhotoLibraryService()
        #endif
        _session = State(initialValue: AppSession(photoLibrary: library))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .modelContainer(container)
        }
    }

    private static func makeContainer() -> ModelContainer {
        if let container = try? PersistenceController.makeContainer() {
            return container
        }
        // In-memory fallback keeps the app runnable if store creation fails.
        do {
            return try PersistenceController.makeContainer(inMemory: true)
        } catch {
            fatalError("PicAgo could not create a model container: \(error)")
        }
    }
}

struct RootView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        Group {
            switch session.route {
            case .onboarding:
                OnboardingView()
                    .transition(.opacity)
            case .home:
                HomeView()
                    .transition(.opacity)
            case .game:
                GameView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .result:
                DailyResultView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.28), value: session.route)
    }
}

#if DEBUG
struct PicAgoApp_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environment(AppSession(photoLibrary: MockPhotoLibraryService()))
            .modelContainer(try! PersistenceController.makeContainer(inMemory: true))
    }
}
#endif
