import SwiftUI
import UniformTypeIdentifiers

@MainActor
struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel: OnboardingViewModel
    @State private var step: Int
    @State private var showFileImporter = false
    var isSimplified: Bool
    var onComplete: (() -> Void)?
    
    init(isSimplified: Bool = false, initialProfile: InjuryProfile? = nil, repository: RecoveryRepositoryProtocol, onComplete: (() -> Void)? = nil) {
        self.isSimplified = isSimplified
        self.onComplete = onComplete
        _step = State(initialValue: isSimplified ? 2 : 0)
        _viewModel = State(initialValue: OnboardingViewModel(initialProfile: initialProfile, repository: repository))
    }
    
    var body: some View {
        ZStack {
            AppTheme.adaptiveBackground(for: colorScheme).ignoresSafeArea()
            
            // Dynamic Background Atmosphere
            ZStack {
                Circle()
                    .fill(AppTheme.athleteOrange.opacity(0.08))
                    .blur(radius: 120)
                    .offset(x: -150, y: -250)
                
                Circle()
                    .fill(AppTheme.performanceBlue.opacity(0.08))
                    .blur(radius: 120)
                    .offset(x: 150, y: 250)
            }
            
            VStack(spacing: 0) {
                // Progress Bar
                if !isSimplified {
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { i in
                            Capsule()
                                .fill(step >= i ? AppTheme.athleteOrange : AppTheme.glassBorder(for: colorScheme))
                                .frame(height: 4)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                }
                
                if isSimplified {
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle((colorScheme == .dark ? Color.white : Color.black).opacity(0.5))
                                .padding(12)
                                .background(AppTheme.glassBackground(for: colorScheme))
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
                
                ZStack {
                    switch step {
                    case 0: welcomeStep
                    case 1: healthPermissionsStep
                    case 2: injuryDetailsStep
                    default: EmptyView()
                    }
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: step)
            }
        }
    }
    
    private var welcomeStep: some View {
        VStack(spacing: 40) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(AppTheme.performanceBlue.opacity(0.05))
                    .frame(width: 220, height: 220)
                
                Image(systemName: "figure.walk.arrival")
                    .font(.system(size: 100))
                    .foregroundStyle(AppTheme.accentGradient)
                    .premiumShadow()
            }
            
            VStack(spacing: 20) {
                Text("RehApp Elite")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                
                Text("Tu recuperación, potenciada por\nIA local y privacidad absoluta.")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            Button("COMENZAR ANÁLISIS") {
                withAnimation { step = 1 }
            }
            .buttonStyle(PremiumButtonStyle())
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
    }
    
    private var healthPermissionsStep: some View {
        VStack(spacing: 40) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.pink.opacity(0.05))
                    .frame(width: 220, height: 220)
                
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(Color.pink.gradient)
                    .premiumShadow()
            }
            
            VStack(spacing: 20) {
                Text("Sincroniza tu Salud")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                
                Text("Cierra tus anillos mientras rehabilitas. RehApp guardará tus sesiones automáticamente en Apple Health.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            Button("PERMITIR HEALTHKIT") {
                Task {
                    _ = await viewModel.requestHealthPermissions()
                    withAnimation { step = 2 }
                }
            }
            .buttonStyle(PremiumButtonStyle(color: .pink))
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
    }
    
    private var injuryDetailsStep: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Text("Configura tu Perfil")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                    Text("Nuestra IA local analizará tu caso clínico.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)
                
                VStack(spacing: 20) {
                    HStack(spacing: 16) {
                        premiumTextField(title: "ÁREA AFECTADA", placeholder: "Ej: Rodilla", text: $viewModel.bodyPart, icon: "body")
                        premiumTextField(title: "DEPORTE", placeholder: "Ej: Ciclismo", text: $viewModel.sport, icon: "figure.run")
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("NIVEL DE DOLOR")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle((colorScheme == .dark ? Color.white : Color.black).opacity(0.5))
                            Spacer()
                            Text("\(viewModel.painLevel)/10")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundStyle(AppTheme.athleteOrange)
                        }
                        
                        Slider(value: .init(get: { Double(viewModel.painLevel) }, set: { viewModel.painLevel = Int($0) }), in: 1...10, step: 1)
                            .tint(AppTheme.athleteOrange)
                    }
                    .padding(20)
                    .background(AppTheme.glassBackground(for: colorScheme))
                    .glassCard(cornerRadius: 20)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SÍNTOMAS Y MOLESTIAS")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle((colorScheme == .dark ? Color.white : Color.black).opacity(0.5))
                        
                        TextEditor(text: $viewModel.symptomsDescription)
                            .frame(height: 80)
                            .scrollContentBackground(.hidden)
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                            .padding(12)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(20)
                    .background(AppTheme.glassBackground(for: colorScheme))
                    .glassCard(cornerRadius: 20)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("DÍAS POR SEMANA")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(AppTheme.tertiaryText(for: colorScheme))
                            Spacer()
                            Text("\(viewModel.daysPerWeek) DÍAS")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundStyle(AppTheme.performanceBlue)
                        }
                        
                        Slider(value: .init(get: { Double(viewModel.daysPerWeek) }, set: { viewModel.daysPerWeek = Int($0) }), in: 1...7, step: 1)
                            .tint(AppTheme.performanceBlue)
                        
                        Divider().background(AppTheme.tertiaryText(for: colorScheme).opacity(0.2))
                        
                        HStack {
                            Text("EJERCICIOS POR DÍA")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(AppTheme.tertiaryText(for: colorScheme))
                            Spacer()
                            Text("\(viewModel.exercisesPerDay) EJ")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundStyle(AppTheme.performanceBlue)
                        }
                        
                        Slider(value: .init(get: { Double(viewModel.exercisesPerDay) }, set: { viewModel.exercisesPerDay = Int($0) }), in: 1...5, step: 1)
                            .tint(AppTheme.performanceBlue)

                        Divider().background(AppTheme.tertiaryText(for: colorScheme).opacity(0.2))

                        HStack {
                            Text("DURACIÓN SESIÓN")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(AppTheme.tertiaryText(for: colorScheme))
                            Spacer()
                            Text("\(viewModel.targetDuration) MIN")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundStyle(AppTheme.performanceBlue)
                        }
                        
                        Slider(value: .init(get: { Double(viewModel.targetDuration) }, set: { viewModel.targetDuration = Int($0) }), in: 5...45, step: 5)
                            .tint(AppTheme.performanceBlue)
                    }
                    .padding(20)
                    .background(AppTheme.glassBackground(for: colorScheme))
                    .glassCard(cornerRadius: 20)
                    
                    medicalReportSection
                }
                .padding(.horizontal, 24)
                
                if viewModel.isProcessing {
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(AppTheme.athleteOrange)
                            .scaleEffect(1.5)
                        Text("EJECUTANDO INFERENCIA CLÍNICA...")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(AppTheme.athleteOrange)
                    }
                    .padding(.top, 20)
                } else {
                    Button(viewModel.initialProfile == nil ? "GENERAR MI ROADMAP" : "GUARDAR CAMBIOS") { // Dynamic button text
                        Task {
                            await viewModel.saveProfile(context: modelContext) // Call saveProfile
                            onComplete?()
                            if isSimplified { dismiss() }
                        }
                    }
                    .buttonStyle(PremiumButtonStyle())
                    .padding(.horizontal, 24)
                    .padding(.bottom, 60) // Increased padding
                }
            }
        }
        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
    }
    
    private func premiumTextField(title: String, placeholder: String, text: Binding<String>, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 10, weight: .black))
                .foregroundStyle((colorScheme == .dark ? Color.white : Color.black).opacity(0.5))
            
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.performanceBlue)
                TextField(placeholder, text: text)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
            }
            .padding(14)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(AppTheme.glassBackground(for: colorScheme))
        .glassCard(cornerRadius: 20)
    }
    
    private var medicalReportSection: some View {
        Button {
            showFileImporter = true
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "doc.badge.plus.fill")
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.selectedReportURL?.lastPathComponent ?? "AÑADIR INFORME MÉDICO")
                        .font(.system(size: 13, weight: .bold))
                    Text("PDF para análisis clínico profundo")
                        .font(.system(size: 10))
                        .opacity(0.7)
                }
                Spacer()
            }
            .foregroundStyle(AppTheme.athleteOrange)
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(AppTheme.athleteOrange.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(AppTheme.athleteOrange.opacity(0.2), lineWidth: 1)
            )
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                viewModel.handleReportSelection(url: url)
            }
        }
    }
}
