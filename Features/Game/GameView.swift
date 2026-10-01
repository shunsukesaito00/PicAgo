import SwiftUI
import SwiftData
import PicAgoCore

struct GameView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.modelContext) private var modelContext
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
            let photoHeight = geo.size.height * 0.58
            VStack(spacing: 0) {
                topBar(vm)
                photoArea(vm, height: photoHeight)
                Spacer(minLength: PicAgoSpacing.sm)
                bottomPanel(vm)
                    .padding(.horizontal, PicAgoSpacing.screenHorizontal)
                    .padding(.bottom, PicAgoSpacing.lg)
            }
        }
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

    private func photoArea(_ vm: GameViewModel, height: CGFloat) -> some View {
        ZStack {
            if let image = vm.currentImage {
                #if canImport(UIKit)
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: height)
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
                    .frame(height: height)
            }

            if case .revealingYear(let correct, _) = vm.phase, let current = vm.current {
                revealOverlay(correct: correct, question: current)
                    .opacity(revealOpacity)
            }
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(String(localized: "a11y.photo")))
    }

    private func revealOverlay(correct: Bool, question: GameQuestion) -> some View {
        VStack(spacing: PicAgoSpacing.xs) {
            Text(correct ? String(localized: "game.correct") : String(localized: "game.incorrect"))
                .font(PicAgoTypography.headline)
                .foregroundStyle(.white)
            Text("\(question.correctYear)")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(.white)
            Text(formattedFullDate(question.creationDate))
                .font(PicAgoTypography.callout)
                .foregroundStyle(.white.opacity(0.9))
            Text(yearsAgoText(question.creationDate))
                .font(PicAgoTypography.body)
                .foregroundStyle(.white.opacity(0.95))
        }
        .padding(PicAgoSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PicAgoColor.photoScrim)
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
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        case .answeringMonth:
            VStack(alignment: .leading, spacing: PicAgoSpacing.sm) {
                Text(String(localized: "game.bonus_month_prompt"))
                    .font(PicAgoTypography.headline)
                    .foregroundStyle(.white)
                monthGrid(vm, interactive: true)
            }
        case .revealingMonth(let correct, let selected):
            VStack(spacing: PicAgoSpacing.md) {
                Text(correct ? String(localized: "game.bonus_correct") : String(localized: "game.bonus_incorrect"))
                    .font(PicAgoTypography.headline)
                    .foregroundStyle(.white)
                monthGrid(vm, interactive: false, selected: selected, wasCorrect: correct)
                Button {
                    vm.continueAfterMonthReveal()
                } label: {
                    Text(String(localized: "game.continue"))
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
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: PicAgoSpacing.yearGridGap
        ) {
            ForEach(choices, id: \.self) { year in
                YearChoiceButton(
                    year: year,
                    state: yearState(year: year, interactive: interactive, selected: selected, wasCorrect: wasCorrect, correct: correctYear)
                ) {
                    vm.selectYear(year)
                }
            }
        }
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
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: PicAgoSpacing.yearGridGap
        ) {
            ForEach(choices, id: \.self) { month in
                Button {
                    vm.selectMonth(month)
                } label: {
                    Text(monthName(month))
                        .font(PicAgoTypography.yearChoice)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(monthBackground(month: month, interactive: interactive, selected: selected, wasCorrect: wasCorrect, correct: correctMonth))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!interactive)
                .accessibilityLabel(Text(monthName(month)))
            }
        }
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
        if interactive { return Color.white.opacity(0.92) }
        if month == selected {
            return (wasCorrect == true) ? PicAgoColor.success : PicAgoColor.accent
        }
        if month == correct { return PicAgoColor.success.opacity(0.85) }
        return Color.white.opacity(0.35)
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
        .modelContainer(try! PersistenceController.makeContainer(inMemory: true))
}
#endif
