import Foundation
import SwiftUI

@MainActor
@Observable
final class OnboardingViewModel {
    private let session: AppSession

    var isRequesting = false
    var showDeniedHelp = false

    init(session: AppSession) {
        self.session = session
    }

    var authorization: PhotoAuthorizationState {
        session.photoLibrary.authorizationState
    }

    func playTapped() async {
        isRequesting = true
        defer { isRequesting = false }

        let state = await session.photoLibrary.requestAuthorization()
        switch state {
        case .authorized, .limited:
            session.finishOnboarding()
        case .denied, .restricted:
            showDeniedHelp = true
        case .notDetermined:
            break
        }
    }

    func continueWithoutGranting() {
        // Still enter Home — empty states guide the user.
        session.finishOnboarding()
    }

    func openSettings() {
        session.photoLibrary.openSystemSettings()
    }
}
