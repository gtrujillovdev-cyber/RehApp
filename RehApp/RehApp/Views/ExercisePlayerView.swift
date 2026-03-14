import SwiftUI

@MainActor
struct ExercisePlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel: ExercisePlayerViewModel
    @State private var showClinicalAdvice = false
    @Namespace private var animation
    
    init(viewModel: ExercisePlayerViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) { // Algn to bottom for controlBar
            VStack(spacing: 0) {
                headerBar
                
                GeometryReader { geo in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            visualContainer(width: geo.size.width)
                                .matchedGeometryEffect(id: "visual", in: animation)
                            
                            HStack(alignment: .top, spacing: 16) {
                                instructionBlock
                                    .transition(.blurReplace)
                                metricsColumn
                            }
                            .padding(.horizontal, 24)
                            
                            // Bottom padding to avoid overlap with controlBar
                            Color.clear.frame(height: 180)
                        }
                        .padding(.top, 10)
                    }
                }
            }
            .background(
                ZStack {
                    AppTheme.adaptiveBackground(for: colorScheme).ignoresSafeArea()
                    sessionGlow
                }
            )
            
            controlBar // Fixed at bottom
            
            metricsOverlay
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.sessionState)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.currentBlock)
        .sheet(isPresented: $showClinicalAdvice) {
                ClinicalAdviceView()
            }
            .sheet(isPresented: $viewModel.showSummary) {
                WorkoutSummaryView(score: viewModel.sessionBlocks.reduce(0) { total, block in
                    if case .exercise(let exercise) = block {
                        return total + (exercise.pointsReward ?? 0)
                    }
                    return total
                }) {
                    dismiss()
                }
            }
    }
    
    // MARK: - Subviews
    
    private var headerBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 20) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                        .padding(10)
                        .background(AppTheme.glassBackground(for: colorScheme))
                        .clipShape(Circle())
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Group {
                        switch viewModel.currentBlock {
                        case .exercise(let exercise):
                            Text(exercise.name.uppercased())
                        case .warmUp:
                            Text(NSLocalizedString("WARM_UP", comment: "").uppercased())
                        case .rest:
                            Text(NSLocalizedString("REST", comment: "").uppercased())
                        case .coolDown:
                            Text(NSLocalizedString("COOL_DOWN", comment: "").uppercased())
                        }
                    }
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                    
                    if case .exercise(let exercise) = viewModel.currentBlock {
                        if viewModel.sessionState == .exercising || viewModel.sessionState == .paused {
                            HStack(spacing: 6) {
                                ProgressView(value: Double(viewModel.currentSet), total: Double(exercise.sets))
                                    .frame(width: 60)
                                    .tint(AppTheme.performanceBlue)
                                
                                Text(String(format: NSLocalizedString("SERIES_X_OF_Y", comment: ""), "\(viewModel.currentSet)", "\(exercise.sets)"))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(AppTheme.performanceBlue)
                            }
                        } else {
                            Text(sessionStateText.uppercased())
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(AppTheme.performanceBlue)
                        }
                    } else {
                        Text(sessionStateText.uppercased())
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppTheme.performanceBlue)
                    }
                }
                
                Spacer()
                
                Button {
                    showClinicalAdvice = true
                } label: {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.athleteOrange)
                        .padding(10)
                        .background(AppTheme.athleteOrange.opacity(0.15))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(AppTheme.athleteOrange.opacity(0.3), lineWidth: 1))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }
    
    private var sessionStateText: String {
        switch viewModel.sessionState {
        case .notStarted: return NSLocalizedString("NOT_STARTED", comment: "")
        case .warmingUp: return NSLocalizedString("WARMING_UP", comment: "")
        case .exercising: return NSLocalizedString("EXERCISE", comment: "")
        case .resting: return NSLocalizedString("REST", comment: "")
        case .coolingDown: return NSLocalizedString("COOLING_DOWN", comment: "")
        case .completed: return NSLocalizedString("COMPLETED", comment: "")
        case .paused: return NSLocalizedString("PAUSED", comment: "")
        }
    }
    
    private var metricsOverlay: some View {
        VStack {
            Spacer()
            if viewModel.sessionState == .exercising || viewModel.sessionState == .paused {
                metricDisplayCard(
                    title: NSLocalizedString("TIME_ELAPSED", comment: ""),
                    value: timeString(from: viewModel.elapsedTime),
                    subTitle: NSLocalizedString("REPETITIONS", comment: ""),
                    subValue: "\(viewModel.currentRep) / \(viewModel.currentExercise.reps)"
                )
                .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .scale.combined(with: .opacity)))
            } else if case .warmUp(let duration) = viewModel.currentBlock, viewModel.sessionState == .warmingUp {
                metricDisplayCard(
                    title: NSLocalizedString("WARM_UP", comment: ""),
                    value: timeString(from: duration - viewModel.elapsedTime),
                    isCountdown: true
                )
            } else if viewModel.sessionState == .resting {
                metricDisplayCard(
                    title: NSLocalizedString("REST", comment: ""),
                    value: timeString(from: (viewModel.currentTimedBlockDuration ?? 0) - viewModel.elapsedTime),
                    isCountdown: true
                )
            } else if case .coolDown(let duration) = viewModel.currentBlock, viewModel.sessionState == .coolingDown {
                metricDisplayCard(
                    title: NSLocalizedString("COOL_DOWN", comment: ""),
                    value: timeString(from: duration - viewModel.elapsedTime),
                    isCountdown: true
                )
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.sessionState)
    }
    
    private func metricDisplayCard(title: String, value: String, subTitle: String? = nil, subValue: String? = nil, isCountdown: Bool = false) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
            Text(value)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundStyle(isCountdown && (Double(value.split(separator: ":").last ?? "0") ?? 0) <= 5 ? AppTheme.athleteOrange : AppTheme.primaryText(for: colorScheme))
                .scaleEffect(isCountdown && (Double(value.split(separator: ":").last ?? "0") ?? 0) <= 3 ? 1.1 : 1.0)
            
            if let st = subTitle, let sv = subValue {
                Text(st)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                Text(sv)
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.performanceBlue)
            }
        }
        .padding(24)
        .background(AppTheme.glassBackground(for: colorScheme))
        .glassCard(cornerRadius: 32)
        .padding(.bottom, 160) // Increased to avoid control bar
        .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 20)
    }
    
    private func timeString(from totalSeconds: TimeInterval) -> String {
        let seconds = Int(max(0, totalSeconds)) % 60
        let minutes = Int(max(0, totalSeconds)) / 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func visualContainer(width: CGFloat) -> some View {
        ZStack {
            AppTheme.glassBackground(for: colorScheme)
                .glassCard(cornerRadius: 32)
            
            VStack(spacing: 0) {
                switch viewModel.currentBlock {
                case .exercise(let exercise):
                    VStack(spacing: 16) {
                        // Media Zone
                        ZStack {
                            Rectangle()
                                .fill(AppTheme.glassBackground(for: colorScheme))
                                .opacity(0.3)
                            
                            Image(exercise.imageResourceName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding(20)
                                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        }
                        .frame(maxHeight: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        
                        // Mini Description Zone
                        VStack(alignment: .leading, spacing: 6) {
                            Text(NSLocalizedString("CLINICAL_OBJECTIVE_LABEL", comment: "Clinical objective section title, e.g. OBJETIVO CLÍNICO").uppercased())
                                .font(.system(size: 8, weight: .black))
                                .foregroundStyle(AppTheme.performanceBlue)
                                .tracking(1)
                            
                            Text(exercise.technicalDescription ?? "")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    
                case .warmUp:
                    stateVisualPlaceholder(icon: "figure.walk", color: AppTheme.performanceBlue)
                case .rest:
                    stateVisualPlaceholder(icon: "timer", color: AppTheme.athleteOrange)
                case .coolDown:
                    stateVisualPlaceholder(icon: "figure.mind.and.body", color: .green)
                }
            }
            .padding(24)
        }
        .frame(height: width * 0.65)
        .padding(.horizontal, 24)
    }
    
    private func stateVisualPlaceholder(icon: String, color: Color) -> some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundStyle(color.gradient)
                .symbolEffect(.bounce, options: .repeating)
            
            Text(sessionStateText.uppercased())
                .font(.system(size: 14, weight: .black))
                .tracking(2)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var instructionBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "list.bullet.clipboard.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.athleteOrange)
                Text(NSLocalizedString("INSTRUCTIONS", comment: ""))
                    .font(.system(size: 10, weight: .black))
                    .tracking(1)
                    .foregroundStyle(AppTheme.athleteOrange)
            }
            
            ScrollView(showsIndicators: false) {
                if case .exercise(let exercise) = viewModel.currentBlock {
                    VStack(alignment: .leading, spacing: 10) {
                        if let instructions = exercise.instructions, !instructions.isEmpty {
                            ForEach(instructions, id: \.self) { instruction in
                                HStack(alignment: .top, spacing: 10) {
                                    Circle()
                                        .fill(AppTheme.performanceBlue)
                                        .frame(width: 4, height: 4)
                                        .padding(.top, 6)
                                    Text(instruction)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                                }
                            }
                        } else {
                            Text(exercise.technicalDescription ?? NSLocalizedString("NO_TECHNICAL_DESCRIPTION", comment: ""))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(NSLocalizedString("NOT_APPLICABLE", comment: ""))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(20)
        .background(AppTheme.glassBackground(for: colorScheme))
        .glassCard(cornerRadius: 24)
    }
    
    private var metricsColumn: some View {
        VStack(spacing: 12) {
            if case .exercise(let exercise) = viewModel.currentBlock {
                metricItem(label: NSLocalizedString("SERIES", comment: ""), value: "\(viewModel.currentSet)/\(exercise.sets)", unit: NSLocalizedString("SET_UNIT", comment: ""))
                metricItem(label: NSLocalizedString("REPETITIONS", comment: ""), value: "\(exercise.reps)", unit: NSLocalizedString("REP_UNIT", comment: ""))
                metricItem(label: NSLocalizedString("REWARD", comment: ""), value: "+\(exercise.pointsReward ?? 10)", unit: NSLocalizedString("POINTS_UNIT", comment: ""), color: .yellow)
            } else {
                metricItem(label: "---", value: "--", unit: "--")
            }
        }
        .frame(width: 100)
    }
    
    private func metricItem(label: String, value: String, unit: String, color: Color = .white) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(AppTheme.tertiaryText(for: colorScheme))
            
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(color == .white ? AppTheme.primaryText(for: colorScheme) : color)
            
            Text(unit)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(AppTheme.tertiaryText(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AppTheme.glassBackground(for: colorScheme))
        .glassCard(cornerRadius: 16)
    }
    
    private var controlBar: some View {
        VStack(spacing: 16) {
            switch viewModel.sessionState {
            case .notStarted:
                actionButton(NSLocalizedString("START_SESSION", comment: ""), color: AppTheme.athleteOrange) {
                    viewModel.startSession()
                }
            case .exercising:
                HStack(spacing: 16) {
                    actionButton(NSLocalizedString("PAUSE", comment: ""), color: .orange) {
                        viewModel.pauseSession()
                    }
                    actionButton(NSLocalizedString("COMPLETE_SET", comment: ""), color: .green) {
                        Task { await viewModel.completeCurrentExerciseSet() }
                    }
                }
            case .paused:
                HStack(spacing: 16) {
                    actionButton(NSLocalizedString("RESUME", comment: ""), color: AppTheme.athleteOrange) {
                        viewModel.resumeSession()
                    }
                    actionButton(NSLocalizedString("SKIP_BLOCK", comment: ""), color: .red) {
                        viewModel.skipCurrentBlock()
                    }
                }
            case .warmingUp, .resting, .coolingDown:
                actionButton(NSLocalizedString("SKIP_BLOCK", comment: ""), color: .red) {
                    viewModel.skipCurrentBlock()
                }
            case .completed:
                actionButton(NSLocalizedString("VIEW_SUMMARY", comment: ""), color: AppTheme.athleteOrange) {
                    // Handled by sheet
                }
            }
        }
        .padding(32)
        .background(
            ZStack {
                AppTheme.adaptiveBackground(for: colorScheme)
                LinearGradient(colors: [.clear, (colorScheme == .dark ? Color.black : Color.white).opacity(0.3)], startPoint: .top, endPoint: .bottom)
            }
            .ignoresSafeArea()
        )
    }
    
    private func actionButton(_ title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(color.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .premiumShadow()
        }
    }
    
    private var sessionGlow: some View {
        let color: Color = {
            switch viewModel.sessionState {
            case .warmingUp: return AppTheme.performanceBlue
            case .exercising: return AppTheme.athleteOrange
            case .resting: return .green
            case .coolingDown: return .purple
            default: return .clear
            }
        }()
        
        return Circle()
            .fill(color.opacity(0.12))
            .blur(radius: 80)
            .scaleEffect(1.5)
            .offset(y: -400)
            .ignoresSafeArea()
    }
}
