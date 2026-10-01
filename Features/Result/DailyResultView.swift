import SwiftUI
import PicAgoCore

struct DailyResultView: View {
    @Environment(AppSession.self) private var session
    @State private var celebrate = false

    var body: some View {
        ZStack {
            SoftAtmosphereBackground()

            VStack(alignment: .leading, spacing: PicAgoSpacing.lg) {
                BrandMark(size: .compact)

                Spacer(minLength: PicAgoSpacing.md)

                Text(String(localized: "result.title"))
                    .font(PicAgoTypography.hero)
                    .foregroundStyle(PicAgoColor.ink)

                if let share = session.lastResultShare {
                    scoreBlock(share)

                    if share.score.isPerfect {
                        Text(String(localized: "result.perfect"))
                            .font(PicAgoTypography.headline)
                            .foregroundStyle(PicAgoColor.accent)
                            .scaleEffect(celebrate ? 1 : 0.92)
                            .opacity(celebrate ? 1 : 0)
                    }

                    if session.lastBonusCorrect > 0 {
                        Text(String(localized: "result.bonus \(session.lastBonusCorrect)"))
                            .font(PicAgoTypography.callout)
                            .foregroundStyle(PicAgoColor.inkSecondary)
                    }

                    Text(String(localized: "result.streak \(share.streak)"))
                        .font(PicAgoTypography.body)
                        .foregroundStyle(PicAgoColor.inkSecondary)

                    ShareLink(item: share.makeText()) {
                        Label(String(localized: "result.share"), systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityHint(Text(String(localized: "result.share_hint")))
                }

                Spacer()

                Button {
                    session.returnHome()
                } label: {
                    Text(String(localized: "result.done"))
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.horizontal, PicAgoSpacing.screenHorizontal)
            .padding(.vertical, PicAgoSpacing.xl)
        }
        .onAppear {
            if session.lastResultShare?.score.isPerfect == true {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                    celebrate = true
                }
            }
        }
    }

    private func scoreBlock(_ share: SharePayload) -> some View {
        VStack(alignment: .leading, spacing: PicAgoSpacing.xs) {
            Text(share.score.displayFraction)
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(PicAgoColor.ink)
                .accessibilityLabel(Text(String(localized: "a11y.score \(share.score.correctCount) \(share.score.totalQuestions)")))
            Text("\(share.score.percentage)%")
                .font(PicAgoTypography.title)
                .foregroundStyle(PicAgoColor.accent)
            Text(share.results.map { $0 ? "🟩" : "🟥" }.joined())
                .font(PicAgoTypography.headline)
                .accessibilityHidden(true)
        }
    }
}

#if DEBUG
#Preview("Result") {
    let session = AppSession(photoLibrary: MockPhotoLibraryService())
    session.lastResultShare = SharePayload(
        score: MemoryScore(correctCount: 4),
        streak: 3,
        results: [true, true, false, true, true]
    )
    session.lastBonusCorrect = 1
    return DailyResultView()
        .environment(session)
}
#endif
