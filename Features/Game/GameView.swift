import SwiftUI
import SwiftData
import PicAgoCore

struct GameView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var viewModel: GameViewModel?
    @State private var revealOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let viewModel {
                switch viewModel.phase {
                case .loading:
                    ProgressView()
                        .tint(.white)
                        .accessibilityLabel(Text(String(localized: "game.loading")))
                case .empty:
                    emptyState
                case .finished:
                    ProgressView()
                        .tint(.white)
                default:
                    gameContent(viewModel)
                }
            }
        }
        .task {
            if viewModel == nil {
                viewModel = GameViewModel(session: session, modelContext: modelContext)
            }
            await viewModel?.start()
        }
        .onChange(of: viewModel?.phase) { _, newPhase in
            if case .revealingYear = newPhase {
                revealOpacity = 0
                withAnimation(.easeOut(duration: 0.35)) { revealOpacity = 1 }
            }
            if case .revealingMonth = newPhase {
                revealOpacity = 0
                withAnimation(.easeOut(duration: 0.35)) { revealOpacity = 1 }
            }
        }
    }

    private func gameContent(_ vm: GameViewModel) -> some View {
        GeometryReader { geo in
            let photoHeight = photoHeight(for: geo.size.height, phase: vm.phase)
            VStack(spacing: 0) {
                topBar(vm)
                photoArea(vm, height: photoHeight, width: geo.size.width)
                bottomPanel(vm)
                    .padding(.top, PicAgoSpacing.md)
                    .padding(.horizontal, PicAgoSpacing.screenHorizontal)
                    .padding(.bottom, PicAgoSpacing.lg)
                    .frame(maxWidth: .infinity, alignment: .top)
                Spacer(minLength: 0)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
    }

    /// Keep photo ~50–65% of the first viewport; shrink slightly for reveal + large Dynamic Type.
    private func photoHeight(for totalHeight: CGFloat, phase: GameViewModel.Phase) -> CGFloat {
        let revealing: Bool = {
            switch phase {
            case .revealingYear, .revealingMonth: return true
            default: return false
            }
        }()
        var fraction: CGFloat = revealing ? 0.52 : 0.58
        if dynamicTypeSize.isAccessibilitySize {
            fraction = revealing ? 0.46 : 0.50
        } else if dynamicTypeSize > .xxxLarge {
            fraction = revealing ? 0.48 : 0.54
        }
        return min(max(totalHeight * fraction, totalHeight * 0.45), totalHeight * 0.65)
    }

    private func topBar(_ vm: GameViewModel) -> some View {
        HStack {
            Button {
                session.returnHome()
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(PicAgoSpacing.sm)
            }
            .accessibilityLabel(Text(String(localized: "game.close")))

            Spacer()
            Text(vm.progressLabel)
                .font(PicAgoTypography.callout)
                .foregroundStyle(.white.opacity(0.9))
                .accessibilityLabel(Text(String(localized: "a11y.progress \(vm.index + 1) \(vm.questions.count)")))
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, PicAgoSpacing.md)
        .padding(.top, PicAgoSpacing.xs)
    }

    private func photoArea(_ vm: GameViewModel, height: CGFloat, width: CGFloat) -> some View {
        ZStack {
            if let image = vm.currentImage {
                #if canImport(UIKit)
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()
                #endif
            } else {
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .overlay {
                        Image(systemName: "photo")
                            .font(.system(size: 36))
                            .foregroundStyle(.white.opacity(0.4))
                    }
            }

            if case .revealingYear(let correct, _) = vm.phase, let current = vm.current {
                revealOverlay(correct: correct, question: current)
                    .opacity(revealOpacity)
            }
        }
        .frame(width: width, height: height)
        .clipped()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(String(localized: "a11y.photo")))
    }

    private func revealOverlay(correct: Bool, question: GameQuestion) -> some View {
        VStack(spacing: PicAgoSpacing.xs) {
            Text(correct ? String(localized: "game.correct") : String(localized: "game.incorrect"))
                .font(PicAgoTypography.headline)
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Text(verbatim: "\(question.correctYear)")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .monospacedDigit()
            Text(formattedFullDate(question.creationDate))
                .font(PicAgoTypography.callout)
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.center)
            Text(yearsAgoText(question.creationDate))
                .font(PicAgoTypography.body)
                .foregroundStyle(.white.opacity(0.95))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, PicAgoSpacing.lg)
        .padding(.vertical, PicAgoSpacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.55),
                    Color.black.opacity(0.28),
                    Color.black.opacity(0.40)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    @ViewBuilder
    private func bottomPanel(_ vm: GameViewModel) -> some View {
        switch vm.phase {
        case .answeringYear:
            yearGrid(vm, interactive: true)
        case .revealingYear(let correct, let selected):
            VStack(spacing: PicAgoSpacing.md) {
                yearGrid(vm, interactive: false, selected: selected, wasCorrect: correct)
                Button {
                    vm.continueAfterYearReveal()
                } label: {
                    Text(String(localized: "game.continue"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        case .answeringMonth:
            VStack(alignment: .leading, spacing: PicAgoSpacing.sm) {
                Text(String(localized: "game.bonus_month_prompt"))
                    .font(PicAgoTypography.headline)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                monthGrid(vm, interactive: true)
            }
        case .revealingMonth(let correct, let selected):
            VStack(spacing: PicAgoSpacing.md) {
                Text(correct ? String(localized: "game.bonus_correct") : String(localized: "game.bonus_incorrect"))
                    .font(PicAgoTypography.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                monthGrid(vm, interactive: false, selected: selected, wasCorrect: correct)
                Button {
                    vm.continueAfterMonthReveal()
                } label: {
                    Text(String(localized: "game.continue"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        default:
            EmptyView()
        }
    }

    private func yearGrid(
        _ vm: GameViewModel,
        interactive: Bool,
        selected: Int? = nil,
        wasCorrect: Bool? = nil
    ) -> some View {
        let choices = vm.current?.yearChoices ?? []
        let correctYear = vm.current?.correctYear
        return LazyVGrid(
            columns: [
                GridItem(.flexible(minimum: 0), spacing: PicAgoSpacing.yearGridGap),
                GridItem(.flexible(minimum: 0), spacing: PicAgoSpacing.yearGridGap)
            ],
            spacing: PicAgoSpacing.yearGridGap
        ) {
            ForEach(choices, id: \.self) { year in
                YearChoiceButton(
                    year: year,
                    state: yearState(
                        year: year,
                        interactive: interactive,
                        selected: selected,
                        wasCorrect: wasCorrect,
                        correct: correctYear
                    )
                ) {
                    vm.selectYear(year)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }

    private func monthGrid(
        _ vm: GameViewModel,
        interactive: Bool,
        selected: Int? = nil,
        wasCorrect: Bool? = nil
    ) -> some View {
        let choices = vm.current?.monthChoices ?? []
        let correctMonth = vm.current?.correctMonth
        return LazyVGrid(
            columns: [
                GridItem(.flexible(minimum: 0), spacing: PicAgoSpacing.yearGridGap),
                GridItem(.flexible(minimum: 0), spacing: PicAgoSpacing.yearGridGap)
            ],
            spacing: PicAgoSpacing.yearGridGap
        ) {
            ForEach(choices, id: \.self) { month in
                Button {
                    vm.selectMonth(month)
                } label: {
                    Text(monthName(month))
                        .font(PicAgoTypography.yearChoice)
                        .foregroundStyle(monthForeground(month: month, interactive: interactive, selected: selected, wasCorrect: wasCorrect, correct: correctMonth))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .padding(.vertical, PicAgoSpacing.xs)
                        .background(monthBackground(month: month, interactive: interactive, selected: selected, wasCorrect: wasCorrect, correct: correctMonth))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!interactive)
                .accessibilityLabel(Text(monthName(month)))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func yearState(
        year: Int,
        interactive: Bool,
        selected: Int?,
        wasCorrect: Bool?,
        correct: Int?
    ) -> YearChoiceButton.YearChoiceState {
        guard !interactive else { return .idle }
        if year == selected {
            return (wasCorrect == true) ? .selectedCorrect : .selectedWrong
        }
        if year == correct { return .selectedCorrect }
        return .disabled
    }

    private func monthBackground(
        month: Int,
        interactive: Bool,
        selected: Int?,
        wasCorrect: Bool?,
        correct: Int?
    ) -> Color {
        if interactive { return PicAgoColor.choiceFill }
        if month == selected {
            return (wasCorrect == true) ? PicAgoColor.success : PicAgoColor.accent
        }
        if month == correct { return PicAgoColor.success.opacity(0.9) }
        return PicAgoColor.choiceFillMuted
    }

    private func monthForeground(
        month: Int,
        interactive: Bool,
        selected: Int?,
        wasCorrect: Bool?,
        correct: Int?
    ) -> Color {
        if interactive { return PicAgoColor.choiceInk }
        if month == selected || month == correct { return .white }
        return PicAgoColor.choiceInkMuted
    }

    private var emptyState: some View {
        VStack(spacing: PicAgoSpacing.md) {
            Text(String(localized: "empty.few_photos_title"))
                .font(PicAgoTypography.title)
                .foregroundStyle(.white)
            Text(String(localized: "empty.few_photos_body"))
                .font(PicAgoTypography.body)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            Button {
                session.returnHome()
            } label: {
                Text(String(localized: "game.back_home"))
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, PicAgoSpacing.xl)
        }
        .padding()
    }

    private func formattedFullDate(_ date: Date) -> String {
        date.formatted(date: .long, time: .omitted)
    }

    private func yearsAgoText(_ date: Date) -> String {
        let years = DateLogic.yearsAgo(from: date)
        return String(localized: "game.years_ago \(years)")
    }

    private func monthName(_ month: Int) -> String {
        var components = DateComponents()
        components.month = month
        let date = Calendar.current.date(from: components) ?? Date()
        return date.formatted(.dateTime.month(.wide))
    }
}

#if DEBUG
#Preview("Game") {
    GameView()
        .environment(AppSession(photoLibrary: MockPhotoLibraryService()))
        .modelContainer(for: [DailyChallengeRecord.self, StreakRecord.self], inMemory: true)
}
#endif
