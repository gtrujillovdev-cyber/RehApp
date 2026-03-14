import SwiftUI
import SwiftData
import Charts

/// Vista principal de la aplicación (Dashboard).
@MainActor
struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    @Environment(SettingsViewModel.self) private var settings
    var viewModel: DashboardViewModel
    @State private var showOnboarding = false
    @State private var showSettings = false
    @State private var isEditingProfile = false
    @State private var profileToEdit: InjuryProfile?
    
    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                headerActionSection
                
                statsGrid
                
                if let profile = viewModel.selectedProfile {
                    summarySection(roadmap: profile.roadmaps.last)
                        .padding(.horizontal, AppTheme.horizontalPadding)
                    
                    clinicalTimelineSection(roadmap: profile.roadmaps.last)
                        .padding(.horizontal, AppTheme.horizontalPadding)
                }
                
                progressChartSection
                    .padding(.horizontal, AppTheme.horizontalPadding)
                
                Color.clear.frame(height: 80)
            }
            .padding(.vertical, 20)
        }
        .background(
            ZStack {
                AppTheme.adaptiveBackground(for: colorScheme).ignoresSafeArea()
                LinearGradient(colors: [AppTheme.performanceBlue.opacity(0.1), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
            }
        )
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("Aceptar", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(isSimplified: true, repository: viewModel.repository) {
                viewModel.fetchLatestData()
            }
        }
        .sheet(isPresented: $isEditingProfile) {
            if let profileToEdit = profileToEdit {
                OnboardingView(isSimplified: true, initialProfile: profileToEdit, repository: viewModel.repository) {
                    viewModel.fetchLatestData()
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(selectedProfile: viewModel.selectedProfile, repository: viewModel.repository)
        }
    }
    
    private var headerActionSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Bienvenido, Atleta")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(AppTheme.performanceBlue)
                        .frame(width: 6, height: 6)
                    Text(viewModel.selectedProfile?.bodyPart.uppercased() ?? "PREPARADO")
                        .font(.system(size: 11, weight: .black))
                        .tracking(1.5)
                        .foregroundStyle(AppTheme.performanceBlue)
                }
            }
            Spacer()
            
            Menu {
                Section("Tus Recuperaciones") {
                    ForEach(viewModel.allProfiles) { profile in
                        Menu {
                            Button {
                                viewModel.selectProfile(profile)
                            } label: {
                                Label("Seleccionar", systemImage: "checkmark.circle")
                            }
                            
                            Button(role: .destructive) {
                                try? viewModel.repository.deleteInjuryProfile(profile)
                                viewModel.fetchLatestData()
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                        } label: {
                            HStack {
                                Text(profile.bodyPart)
                                if profile.id == viewModel.selectedProfile?.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
                
                Divider()
                
                if let selectedProfile = viewModel.selectedProfile {
                    Button {
                        profileToEdit = selectedProfile
                        isEditingProfile = true
                    } label: {
                        Label("Editar Recuperación", systemImage: "pencil.circle.fill")
                    }
                }
                
                Button {
                    showOnboarding = true
                } label: {
                    Label("Nueva Recuperación", systemImage: "plus.circle.fill")
                }
            } label: {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                    .padding(8)
                    .glassCard(cornerRadius: 50)
            }
        }
        .padding(.horizontal, AppTheme.horizontalPadding)
    }
    
    private var statsGrid: some View {
        HStack(spacing: 16) {
            StatCard(title: "Score Total", value: "\(viewModel.stats.score)", icon: "star.fill", color: .yellow)
            StatCard(title: "Racha Actual", value: "\(viewModel.stats.streak)d", icon: "flame.fill", color: AppTheme.athleteOrange)
        }
        .padding(.horizontal, AppTheme.horizontalPadding)
    }
    
    private func summarySection(roadmap: RecoveryRoadmap?) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ESTADO ACTUAL")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                    Text(roadmap == nil ? "Sin Plan Activo" : (roadmap?.phases.first { $0.order == (roadmap?.currentPhaseIndex ?? 0) }?.title ?? "Recuperación"))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                }
                Spacer()
                CircularProgressView(progress: roadmap?.progress ?? 0)
                    .frame(width: 50, height: 50)
            }
            
            Divider().background(AppTheme.glassBorder(for: colorScheme))
            
            Text(roadmap?.aiReasoning ?? "Analiza tu lesión en Ajustes para generar un plan.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                .lineLimit(3)
        }
        .padding(20)
        .background(AppTheme.glassBackground(for: colorScheme))
        .glassCard()
    }
    
    private var progressChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Carga Semanal")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                Spacer()
                Text("Últimos 7 días")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.performanceBlue)
            }
            
            Chart {
                if viewModel.activityLogs.isEmpty {
                    ForEach(0..<7, id: \.self) { i in
                        BarMark(
                            x: .value("Día", "D\(i+1)"),
                            y: .value("Score", 10)
                        )
                        .foregroundStyle(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                    }
                } else {
                    ForEach(viewModel.activityLogs) { log in
                        BarMark(
                            x: .value("Día", log.date, unit: .day),
                            y: .value("Score", log.scoreEarned)
                        )
                        .foregroundStyle(AppTheme.vibrantGradient)
                        .cornerRadius(6)
                    }
                }
            }
            .chartYAxis(.hidden)
            .frame(height: 120)
            .padding(.top, 10)
        }
        .padding(20)
        .glassCard()
    }

    @ViewBuilder
    private func clinicalTimelineSection(roadmap: RecoveryRoadmap?) -> some View {
        if let roadmap = roadmap {
            VStack(alignment: .leading, spacing: 16) {
                Text("Línea de Vida Clínica")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                
                VStack(spacing: 0) {
                    let phases = roadmap.phases.sorted(by: { $0.order < $1.order })
                    ForEach(Array(phases.enumerated()), id: \.element.id) { index, phase in
                        TimelineNode(
                            phase: phase,
                            isLast: index == phases.count - 1,
                            isCurrent: phase.order == roadmap.currentPhaseIndex
                        )
                    }
                }
                .padding(20)
                .glassCard()
            }
        }
    }
}

// MARK: - Subviews

struct StatCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: icon)
                            .foregroundStyle(color)
                            .font(.system(size: 16))
                    )
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.tertiaryText(for: colorScheme))
                    .tracking(0.5)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}

struct TimelineNode: View {
    let phase: RecoveryPhase
    let isLast: Bool
    let isCurrent: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                Circle()
                    .fill(isCurrent ? AppTheme.performanceBlue : Color.gray.opacity(0.3))
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(isCurrent ? AppTheme.performanceBlue.opacity(0.3) : .clear, lineWidth: 8)
                    )
                
                if !isLast {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 2)
                        .frame(minHeight: 40)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(phase.title.uppercased())
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(isCurrent ? AppTheme.performanceBlue : .gray)
                
                Text(phase.phaseDescription)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .padding(.bottom, isLast ? 0 : 20)
            }
        }
    }
}

struct CircularProgressView: View {
    let progress: Double
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 6)
                .opacity(0.1)
                .foregroundStyle(AppTheme.performanceBlue)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                .foregroundStyle(AppTheme.performanceBlue)
                .rotationEffect(Angle(degrees: 270.0))
            
            Text("\(Int(progress * 100))%")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
        }
    }
}
