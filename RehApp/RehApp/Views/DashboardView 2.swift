import SwiftUI
import SwiftData
import Charts

@MainActor
struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    @Environment(SettingsViewModel.self) private var settings
    var viewModel: DashboardViewModel
    @State private var showOnboarding = false
    @State private var showSettings = false
    @State private var isEditingProfile = false
    @State private var profileToEdit: InjuryProfile? // To pass to the editor
    
    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                headerActionSection
                
                statsGrid
                
                if !viewModel.prehabRoutine.isEmpty {
                    prehabSection
                }
                
                progressChartSection
                
                // Extra space at bottom for tab bar
                Color.clear.frame(height: 40)
            }
            .padding(.vertical, 20)
        }
        .background(
            ZStack {
                (colorScheme == .dark ? AppTheme.deepSlate : Color(white: 0.95)).ignoresSafeArea()
                // Subtle gradient glow
                LinearGradient(colors: [AppTheme.performanceBlue.opacity(0.1), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
            }
        )
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
                        Button {
                            viewModel.selectProfile(profile)
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
                    
                    Button(role: .destructive) {
                        viewModel.deleteInjuryProfile(selectedProfile)
                    } label: {
                        Label("Eliminar Recuperación", systemImage: "minus.circle.fill")
                    }
                }
                
                Button(role: .none) {
                    showOnboarding = true
                } label: {
                    Label("Nueva Recuperación", systemImage: "plus.circle.fill")
                }
                
                Divider()
                
                Button {
                    showSettings = true
                } label: {
                    Label("Ajustes", systemImage: "gearshape.fill")
                }
            } label: {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                    .padding(8)
                    .glassCard(cornerRadius: 50)
            }
        }
        .padding(.horizontal, 24)
    }
    
    private var statsGrid: some View {
        HStack(spacing: 16) {
            StatCard(title: "Score Total", value: "\(viewModel.stats.score)", icon: "star.fill", color: .yellow)
            StatCard(title: "Racha Actual", value: "\(viewModel.stats.streak)d", icon: "flame.fill", color: AppTheme.athleteOrange)
        }
        .padding(.horizontal, 24)
    }
    
    private var prehabSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("COACH PREVENTIVO")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(AppTheme.athleteOrange)
                    Text("Mantenimiento Diario")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                }
                Spacer()
                
                if let profile = viewModel.selectedProfile {
                    NavigationLink {
                        if !viewModel.prehabRoutine.isEmpty {
                            prehabOverview(profile: profile)
                        }
                    } label: {
                        Text("INICIAR")
                            .font(.system(size: 13, weight: .bold))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(AppTheme.athleteOrange)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                            .premiumShadow()
                    }
                }
            }
            .padding(24)
            .background(
                ZStack {
                    AppTheme.glassBackground(for: colorScheme)
                    Image(systemName: "shield.checkerboard")
                        .font(.system(size: 90))
                        .foregroundStyle(AppTheme.athleteOrange.opacity(0.04))
                        .offset(x: 120, y: 10)
                }
            )
            .glassCard()
        }
        .padding(.horizontal, 24)
    }
    
    private var progressChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Actividad Semanal")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(colorScheme == .dark ? .white : .black)
            
            Chart {
                ForEach(0..<7, id: \.self) { i in
                    BarMark(
                        x: .value("Día", "D\(i+1)"),
                        y: .value("Score", Int.random(in: 15...60))
                    )
                    .foregroundStyle(AppTheme.athleteOrange.gradient)
                    .cornerRadius(6)
                }
            }
            .frame(height: 160)
            .chartYAxis(.hidden)
            .padding(20)
            .glassCard()
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private func prehabOverview(profile: InjuryProfile) -> some View {
        // We create a temporary routine object for the overview
        {
            let routine = DailyRoutine(dayTitle: "RUTINA PREVENTIVA", order: 1)
            routine.exercises = viewModel.prehabRoutine
            return SessionOverviewView(routine: routine, profile: profile, repository: viewModel.repository)
        }()
    }
}

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
