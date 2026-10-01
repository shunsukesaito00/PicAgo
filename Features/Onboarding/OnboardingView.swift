import SwiftUI

struct OnboardingView: View {
    @Environment(AppSession.self) private var session
    @State private var viewModel: OnboardingViewModel?
    @State private var appear = false

    var body: some View {
        ZStack {
            SoftAtmosphereBackground()

            VStack(alignment: .leading, spacing: PicAgoSpacing.lg) {
                Spacer(minLength: PicAgoSpacing.xxl)

                BrandMark(size: .hero)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 12)

                Text(String(localized: "onboarding.tagline"))
                    .font(PicAgoTypography.hero)
                    .foregroundStyle(PicAgoColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 10)

                Text(String(localized: "onboarding.body"))
                    .font(PicAgoTypography.body)
                    .foregroundStyle(PicAgoColor.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                privacyLine

                Spacer()

                if viewModel?.showDeniedHelp == true {
                    deniedHelp
                }

                Button {
                    Task { await viewModel?.playTapped() }
                } label: {
                    Text(String(localized: "onboarding.cta"))
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(viewModel?.isRequesting == true)
                .accessibilityHint(Text(String(localized: "onboarding.cta_hint")))

                Button {
                    viewModel?.continueWithoutGranting()
                } label: {
                    Text(String(localized: "onboarding.later"))
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(.horizontal, PicAgoSpacing.screenHorizontal)
            .padding(.bottom, PicAgoSpacing.xl)
        }
        .onAppear {
            if viewModel == nil {
                viewModel = OnboardingViewModel(session: session)
            }
            withAnimation(.easeOut(duration: 0.45)) {
                appear = true
            }
        }
    }

    private var privacyLine: some View {
        HStack(alignment: .top, spacing: PicAgoSpacing.xs) {
            Image(systemName: "lock.shield")
                .foregroundStyle(PicAgoColor.accent)
                .accessibilityHidden(true)
            Text(String(localized: "privacy.photos_stay"))
                .font(PicAgoTypography.callout)
                .foregroundStyle(PicAgoColor.inkSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var deniedHelp: some View {
        VStack(alignment: .leading, spacing: PicAgoSpacing.sm) {
            Text(String(localized: "onboarding.denied_title"))
                .font(PicAgoTypography.headline)
            Text(String(localized: "onboarding.denied_body"))
                .font(PicAgoTypography.callout)
                .foregroundStyle(PicAgoColor.inkSecondary)
            Button {
                viewModel?.openSettings()
            } label: {
                Text(String(localized: "empty.open_settings"))
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding(PicAgoSpacing.md)
        .background(PicAgoColor.subtleFill)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#if DEBUG
#Preview("Onboarding") {
    OnboardingView()
        .environment(AppSession(photoLibrary: MockPhotoLibraryService(authorizationState: .notDetermined)))
}
#endif
