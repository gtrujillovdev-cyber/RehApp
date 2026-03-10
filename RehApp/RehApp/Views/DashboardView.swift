import SwiftUI
import SwiftData
import Charts

/// Vista principal de la aplicación (Dashboard).
/// Proporciona un resumen del estado de recuperación, estadísticas de gamificación
/// y acceso a rutinas preventivas diarias.
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
                headerActionSection // Saludo y selector de perfiles
                
                statsGrid // Tarjetas de Score y Racha
                
                if !viewModel.prehabRoutine.isEmpty {
                    prehabSection // Sección de Coach Preventivo
                }
                
                progressChartSection // Gráfico de actividad semanal
                
                Color.clear.frame(height: 40)
            }
            .padding(.vertical, 20)
        }
        .background(
            ZStack {
                // Fondo adaptativo con brillo sutil
                (colorScheme == .dark ? AppTheme.deepSlate : Color(white: 0.95)).ignoresSafeArea()
                LinearGradient(colors: [AppTheme.performanceBlue.opacity(0.1), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
            }
        )
        // El .alert observa viewModel.errorMessage.
        // Cuando el ViewModel asigna un error, SwiftUI lo detecta (porque @Observable)
        // y presenta el alert automáticamente. Al cerrar, reseteamos el mensaje.
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
    
    /// Cabecera con el selector de perfiles de lesión.
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
            
            // Menú para gestionar múltiples lesiones
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
                }
                
                Button(role: .none) {
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
        .padding(.horizontal, 24)
    }
    
    /// Grid de estadísticas con diseño "Glass" y colores vibrantes.
    private var statsGrid: some View {
        HStack(spacing: 16) {
            StatCard(title: "Score Total", value: "\(viewModel.stats.score)", icon: "star.fill", color: .yellow)
            StatCard(title: "Racha Actual", value: "\(viewModel.stats.streak)d", icon: "flame.fill", color: AppTheme.athleteOrange)
        }
        .padding(.horizontal, 24)
    }
    
    /// Tarjeta para iniciar la rutina preventiva (Prehab).
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
    
    /// Gráfico de barras usando Swift Charts para visualizar el progreso.
    private var progressChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Actividad Semanal")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(colorScheme == .dark ? .white : .black)
            
            Chart {
                if viewModel.activityLogs.isEmpty {
                    // Estado vacío o placeholder decorativo
                    ForEach(0..<7, id: \.self) { i in
                        BarMark(
                            x: .value("Día", "D\(i+1)"),
                            y: .value("Score", 0)
                        )
                        .foregroundStyle(Color.gray.opacity(0.2))
                        .cornerRadius(6)
                    }
                } else {
                    ForEach(viewModel.activityLogs) { log in
                        BarMark(
                            x: .value("Día", log.date, unit: .day),
                            y: .value("Score", log.scoreEarned)
                        )
                        .foregroundStyle(AppTheme.athleteOrange.gradient)
                        .cornerRadius(6)
                    }
                }
            }
            .frame(height: 160)
            .padding(20)
            .glassCard()
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private func prehabOverview(profile: InjuryProfile) -> some View {
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
