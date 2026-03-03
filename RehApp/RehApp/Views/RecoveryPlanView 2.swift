import SwiftUI
import SwiftData

@MainActor
struct RecoveryPlanView: View {
    @Environment(\.colorScheme) private var colorScheme
    var viewModel: DashboardViewModel
    
    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                headerSection
                
                if let roadmap = viewModel.currentRoadmap, let profile = viewModel.selectedProfile {
                    // Today's Routine Highlight
                    todaysRoutineSection(roadmap: roadmap, profile: profile)
                    
                    // Full Strategy Overview
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("ESTRATEGIA 12 SEMANAS")
                                    .font(.system(size: 10, weight: .black))
                                    .tracking(1.2)
                                    .foregroundStyle(AppTheme.athleteOrange)
                                Text("\(roadmap.phases.count) FASES CLÍNICAS")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(profile.daysPerWeek) DÍAS/SEM")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(AppTheme.performanceBlue)
                                Text("\(profile.exercisesPerDay) EJ/DÍA")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(AppTheme.performanceBlue)
                            }
                        }
                        .padding(.horizontal, 4)
                        
                        ForEach(roadmap.phases.sorted(by: { $0.order < $1.order })) { phase in
                            PhaseSection(phase: phase, profile: profile, repository: viewModel.repository)
                        }
                } else {
                    ContentUnavailableView {
                        Label("Sin Plan Activo", systemImage: "figure.walk.circle")
                    } description: {
                        Text("Configura tu perfil para generar una hoja de ruta clínica personalizada por IA.")
                    }
                    .padding(32)
                    .glassCard()
                }
                
                Color.clear.frame(height: 100) // Ensure enough space above tab bar
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
        .background((colorScheme == .dark ? AppTheme.deepSlate : Color(white: 0.95)).ignoresSafeArea())
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Hoja de Ruta")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
            
            HStack(spacing: 8) {
                Capsule()
                    .fill(AppTheme.performanceBlue.opacity(0.15))
                    .frame(width: 60, height: 20)
                    .overlay(
                        Text("ACTIVO")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(AppTheme.performanceBlue)
                    )
                
                Text(viewModel.selectedProfile?.bodyPart.uppercased() ?? "PLAN")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(AppTheme.tertiaryText(for: colorScheme))
            }
        }
    }
    
    @ViewBuilder
    private func todaysRoutineSection(roadmap: RecoveryRoadmap, profile: InjuryProfile) -> some View {
        if let currentPhase = roadmap.phases.sorted(by: { $0.order < $1.order }).first,
           let todayRoutine = currentPhase.dailyRoutines.sorted(by: { $0.order < $1.order }).first {
            
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(AppTheme.athleteOrange)
                    Text("TU SESIÓN DE HOY")
                        .font(.system(size: 11, weight: .black))
                        .tracking(1)
                        .foregroundStyle(AppTheme.athleteOrange)
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 24) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(todayRoutine.dayTitle)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                            Text("Fase \(currentPhase.order): \(currentPhase.title.replacingOccurrences(of: "Fase \(currentPhase.order): ", with: ""))")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                        }
                        Spacer()
                        
                        NavigationLink {
                             SessionOverviewView(routine: todayRoutine, profile: profile, repository: viewModel.repository)
                        } label: {
                            HStack(spacing: 8) {
                                Text("COMENZAR")
                                Image(systemName: "play.fill")
                            }
                            .font(.system(size: 13, weight: .bold))
                            .padding(.horizontal, 22)
                            .padding(.vertical, 12)
                            .background(AppTheme.athleteOrange)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                            .premiumShadow()
                        }
                    }
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(todayRoutine.exercises.prefix(3)) { exercise in
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(AppTheme.performanceBlue.opacity(0.6))
                                
                                Text(exercise.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                                
                                Spacer()
                                
                                Text("\(exercise.sets)x\(exercise.reps)")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundStyle(AppTheme.tertiaryText(for: colorScheme))
                            }
                        }
                    }
                }
                .padding(24)
                .background(AppTheme.athleteOrange.opacity(0.03))
                .glassCard()
            }
        }
    }
}

struct PhaseSection: View {
    @Environment(\.colorScheme) private var colorScheme
    let phase: RecoveryPhase
    let profile: InjuryProfile
    let repository: RecoveryRepositoryProtocol
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            
            let routines = phase.dailyRoutines.sorted(by: { $0.order < $1.order })
            let weeks = stride(from: 0, to: routines.count, by: profile.daysPerWeek).map {
                Array(routines[$0..<min($0 + profile.daysPerWeek, routines.count)])
            }
            
            ForEach(Array(weeks.enumerated()), id: \.offset) { index, weekRoutines in
                let weekNum = ((phase.order - 1) * 3) + index + 1
                VStack(alignment: .leading, spacing: 12) {
                    Text("SEMANA \(weekNum)")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(AppTheme.athleteOrange.opacity(0.8))
                        .padding(.leading, 4)
                    
                    VStack(spacing: 10) {
                        ForEach(weekRoutines) { routine in
                            NavigationLink {
                                SessionOverviewView(routine: routine, profile: profile, repository: repository)
                            } label: {
                                RoutineRow(routine: routine)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(20)
        .glassCard()
    }
    
    private var header: some View {
        HStack {
            Text("FASE \(phase.order)")
                .font(.system(size: 10, weight: .black))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AppTheme.performanceBlue.opacity(0.2))
                .foregroundStyle(AppTheme.performanceBlue)
                .cornerRadius(4)
            
            Text(phase.title.replacingOccurrences(of: "Fase \(phase.order): ", with: "").uppercased())
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
        }
    }
}

struct RoutineRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let routine: DailyRoutine
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(AppTheme.glassBorder(for: colorScheme))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(String(routine.dayTitle.prefix(1)))
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(routine.dayTitle.components(separatedBy: " (Semana").first ?? routine.dayTitle)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                Text("\(routine.exercises.count) ejercicios técnicos")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppTheme.tertiaryText(for: colorScheme))
        }
        .padding(14)
        .background(AppTheme.glassBackground(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
