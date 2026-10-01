import SwiftUI
import SwiftData
import PicAgoCore

struct HomeView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HomeViewModel?
    @State private var appear = false

    var body: some View {
        ZStack {
            SoftAtmosphereBackground()

            VStack(alignment: .leading, spacing: PicAgoSpacing.lg) {
                HStack {
                    BrandMark(size: .regular)
                    Spacer()
                    if let streak = viewModel?.streak.currentStreak, streak > 0 {
                        Label("\(streak)", systemImage: "flame.fill")
                            .font(PicAgoTypography.headline)
                            .foregroundStyle(PicAgoColor.accent)
                            .accessibilityLabel(Text(String(localized: "a11y.streak \(streak)")))
                    }
                }

                Spacer(minLength: PicAgoSpacing.md)

                Text(String(localized: "home.headline"))
                    .font(PicAgoTypography.hero)
                    .foregroundStyle(PicAgoColor.ink)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 8)

                Text(String(localized: "home.subhead"))
                    .font(PicAgoTypography.body)
                    .foregroundStyle(PicAgoColor.inkSecondary)

                statusBlock

                Spacer()

                primaryAction

                privacyFooter
            }
            .padding(.horizontal, PicAgoSpacing.screenHorizontal)
            .padding(.vertical, PicAgoSpacing.xl)
        }
        .task {
            if viewModel == nil {
                viewModel = HomeViewModel(session: session, modelContext: modelContext)
            }
            await viewModel?.refresh()
            withAnimation(.easeOut(duration: 0.4)) { appear = true }
        }
        .onChange(of: session.route) { _, newRoute in
            if newRoute == .home {
                Task { await viewModel?.refresh() }
            }
        }
    }

    @ViewBuilder
    private var statusBlock: some View {
        if let viewModel {
            if viewModel.needsPermission {
                emptyPanel(
                    title: String(localized: "empty.permission_title"),
                    body: String(localized: "empty.permission_body")
                )
            } else if viewModel.tooFewPhotos {
                emptyPanel(
                    title: String(localized: "empty.few_photos_title"),
                    body: String(localized: "empty.few_photos_body")
                )
            } else if case .todayComplete(let score) = viewModel.presentation {
                VStack(alignment: .leading, spacing: PicAgoSpacing.xs) {
                    Label(String(localized: "home.today_complete"), systemImage: "checkmark.circle.fill")
                        .font(PicAgoTypography.title)
                        .foregroundStyle(PicAgoColor.success)
                    Text("\(score.displayFraction) · \(score.percentage)%")
                        .font(PicAgoTypography.headline)
                        .foregroundStyle(PicAgoColor.ink)
                }
                .accessibilityElement(children: .combine)
            } else if case .inProgress(let answered) = viewModel.presentation {
                Text(String(localized: "home.in_progress \(answered)"))
                    .font(PicAgoTypography.callout)
                    .foregroundStyle(PicAgoColor.inkSecondary)
            }
        }
    }

    @ViewBuilder
    private var primaryAction: some View {
        if let viewModel {
            if viewModel.needsPermission {
                Button {
                    Task { await viewModel.requestPermission() }
                } label: {
                    Text(String(localized: "onboarding.cta"))
                }
                .buttonStyle(PrimaryButtonStyle())

                Button {
                    viewModel.openSettings()
                } label: {
                    Text(String(localized: "empty.open_settings"))
                }
                .buttonStyle(SecondaryButtonStyle())
            } else if viewModel.tooFewPhotos {
                Button {
                    viewModel.openSettings()
                } label: {
                    Text(String(localized: "empty.add_photos"))
                }
                .buttonStyle(PrimaryButtonStyle())
            } else if viewModel.isCompletedToday {
                Text(String(localized: "home.come_back_tomorrow"))
                    .font(PicAgoTypography.callout)
                    .foregroundStyle(PicAgoColor.inkSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                #if DEBUG
                Button("DEBUG Reset Today") {
                    try? viewModel.developerResetToday()
                }
                .buttonStyle(SecondaryButtonStyle())
                #endif
            } else {
                Button {
                    viewModel.play()
                } label: {
                    Text(String(localized: "home.play"))
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityHint(Text(String(localized: "home.play_hint")))
            }
        }
    }

    private func emptyPanel(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: PicAgoSpacing.xs) {
            Text(title)
                .font(PicAgoTypography.headline)
            Text(body)
                .font(PicAgoTypography.callout)
                .foregroundStyle(PicAgoColor.inkSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var privacyFooter: some View {
        Text(String(localized: "privacy.photos_stay"))
            .font(PicAgoTypography.caption)
            .foregroundStyle(PicAgoColor.inkSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

#if DEBUG
#Preview("Home") {
    HomeView()
        .environment(AppSession(photoLibrary: MockPhotoLibraryService()))
        .modelContainer(try! PersistenceController.makeContainer(inMemory: true))
}
#endif
