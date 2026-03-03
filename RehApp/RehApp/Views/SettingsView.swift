import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss: DismissAction
    @Environment(\.modelContext) private var context: ModelContext
    @Environment(SettingsViewModel.self) private var viewModel
    @Environment(\.colorScheme) private var colorScheme
    @Query private var profiles: [InjuryProfile]
    
    var selectedProfile: InjuryProfile?
    var repository: RecoveryRepositoryProtocol
    
    @State private var showExportSheet = false
    @State private var csvContent: String?
    @State private var isEditingProfile = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dynamic background that adapts to theme
                (colorScheme == .dark ? AppTheme.deepSlate : Color(white: 0.95))
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Clinical Profile
                        if let profile = selectedProfile {
                            settingsSection(title: "MI PERFIL CLÍNICO", icon: "figure.walk.circle.fill") {
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(profile.bodyPart)
                                            .font(.system(size: 18, weight: .bold, design: .rounded))
                                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                                        Text(profile.sport)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                                    }
                                    Spacer()
                                    Button {
                                        isEditingProfile = true
                                    } label: {
                                        Text("Configurar")
                                            .font(.system(size: 13, weight: .bold))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(AppTheme.athleteOrange.opacity(0.1))
                                            .foregroundStyle(AppTheme.athleteOrange)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }

                        // MARK: - Appearance
                        settingsSection(title: "APARIENCIA", icon: "paintbrush.fill") {
                            HStack {
                                Text("Tema")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                                Spacer()
                                Picker("Tema", selection: Bindable(viewModel).selectedTheme) {
                                    ForEach(SettingsViewModel.AppThemeSelection.allCases, id: \.self) { theme in
                                        Text(theme.rawValue).tag(theme)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(AppTheme.performanceBlue)
                            }
                        }
                        
                        // MARK: - Notifications
                        settingsSection(title: "NOTIFICACIONES", icon: "bell.badge.fill") {
                            VStack(spacing: 20) {
                                customToggle(title: "Recordatorios diarios", icon: "calendar", isOn: Bindable(viewModel).enableExerciseReminders)
                                customToggle(title: "Actualizaciones de progreso", icon: "chart.line.uptrend.xyaxis", isOn: Bindable(viewModel).enableProgressUpdates)
                            }
                        }
                        
                        // MARK: - Data Management
                        settingsSection(title: "DATOS Y PRIVACIDAD", icon: "lock.shield.fill") {
                            VStack(spacing: 20) {
                                customToggle(title: "Sincronizar con HealthKit", icon: "heart.fill", isOn: Binding(
                                    get: { viewModel.isHealthKitEnabled },
                                    set: { if $0 { viewModel.requestHealthKitAuthorization() } else { Bindable(viewModel).isHealthKitEnabled.wrappedValue = false } }
                                ))
                                
                                Button {
                                    let csv = viewModel.generateCSVExport(profiles: profiles)
                                    self.csvContent = csv
                                    self.showExportSheet = true
                                } label: {
                                    HStack {
                                        Label("Exportar datos (CSV)", systemImage: "square.and.arrow.up")
                                            .font(.system(size: 15, weight: .semibold))
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundStyle(AppTheme.tertiaryText(for: colorScheme))
                                    }
                                    .foregroundStyle(AppTheme.performanceBlue)
                                }
                            }
                        }
                        
                        // MARK: - Legal & About
                        settingsSection(title: "ACERCA DE", icon: "info.circle.fill") {
                            VStack(alignment: .leading, spacing: 16) {
                                Link(destination: URL(string: "https://example.com/privacy")!) {
                                    HStack {
                                        Text("Política de Privacidad")
                                        Spacer()
                                        Image(systemName: "arrow.up.right")
                                            .font(.caption)
                                    }
                                }
                                
                                Divider().background(AppTheme.tertiaryText(for: colorScheme).opacity(0.2))
                                
                                HStack {
                                    Text("Versión")
                                    Spacer()
                                    Text("1.0.0 (Build 1)")
                                        .foregroundStyle(AppTheme.tertiaryText(for: colorScheme))
                                }
                            }
                            .font(.system(size: 15))
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                        }
                        
                        Text("Diseñado para atletas por Gtv")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppTheme.tertiaryText(for: colorScheme))
                            .padding(.top, 20)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Ajustes")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Listo") {
                        viewModel.saveSettings()
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.athleteOrange)
                }
            }
            .sheet(isPresented: $showExportSheet) {
                if let csv = csvContent {
                    ShareSheet(items: [csv])
                }
            }
            .sheet(isPresented: $isEditingProfile) {
                if let profile = selectedProfile {
                    OnboardingView(isSimplified: true, initialProfile: profile, repository: repository) {
                        // Profile updated
                    }
                }
            }
        }
    }
    
    private func settingsSection<Content: View>(title: String, icon: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.performanceBlue)
                Text(title)
                    .font(.system(size: 10, weight: .black))
                    .tracking(1.5)
                    .foregroundStyle(AppTheme.tertiaryText(for: colorScheme))
            }
            .padding(.horizontal, 4)
            
            VStack {
                content()
            }
            .padding(20)
            .background(AppTheme.glassBackground(for: colorScheme))
            .glassCard()
        }
    }
    
    private func customToggle(title: String, icon: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                    .frame(width: 24)
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
            }
        }
        .tint(AppTheme.athleteOrange)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView(
        selectedProfile: nil,
        repository: RecoveryRepository(context: try! ModelContainer(for: InjuryProfile.self).mainContext)
    )
}
