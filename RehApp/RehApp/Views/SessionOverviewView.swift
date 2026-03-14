import SwiftUI
import SwiftData

struct SessionOverviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let routine: DailyRoutine
    let profile: InjuryProfile
    let repository: RecoveryRepositoryProtocol
    
    @State private var selectedExercise: Exercise?
    @State private var showCheckin = false
    @State private var navigateToPlayer = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    sessionInfoCard
                        .padding(.top, 60) // Safe margin for floating button
                        .padding(.bottom, 8)
                        
                    exerciseList
                    
                    Color.clear.frame(height: 140) // Bottom button buffer
                }
                .padding(.horizontal, AppTheme.horizontalPadding)
            }
            .background(AppTheme.adaptiveBackground(for: colorScheme))
            
            startSessionButton
        }
        .overlay(alignment: .topLeading) {
            backButton
                .padding(.leading, AppTheme.horizontalPadding)
                .padding(.top, 8)
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedExercise) { exercise in
            ExerciseDetailView(exercise: exercise)
        }
        .sheet(isPresented: $showCheckin) {
            DailyCheckinView(routine: routine) { reportedPain in
                showCheckin = false
                
                // Escalar (reducir) la rutina dinámicamente si el dolor es muy agudo (Punto débil 3)
                if reportedPain >= 8 {
                    scaleDownRoutineForPain()
                }
                
                // Pequeño retardo para permitir que la animación de la hoja (sheet) termine antes de navegar
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    navigateToPlayer = true
                }
            }
        }
        .navigationDestination(isPresented: $navigateToPlayer) {
            ExercisePlayerView(viewModel: ExercisePlayerViewModel(
                sessionBlocks: routine.exercises.map { .exercise($0) },
                profile: profile,
                repository: repository
            ))
        }
    }
    
    private var backButton: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .padding(12)
                    .background(AppTheme.glassBackground(for: colorScheme))
                    .clipShape(Circle())
            }
            Spacer()
        }
    }
    
    private var sessionInfoCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(routine.dayTitle.uppercased())
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(AppTheme.athleteOrange)
            
            Text("Preparación Clínica")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(colorScheme == .dark ? .white : .black)
            
            Text("Sesión diseñada para la \(routine.phase?.title.lowercased() ?? "fase de recuperación").")
                .font(.system(size: 13))
                .foregroundStyle((colorScheme == .dark ? Color.white : Color.black).opacity(0.6))
                .lineLimit(2)
                
            HStack(spacing: 16) {
                Label("\(routine.exercises.count * 4) MIN EST.", systemImage: "clock.fill")
                Label("INTENSIDAD MEDIA", systemImage: "flame.fill")
            }
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(AppTheme.performanceBlue)
            .padding(.top, 4)
        }
    }
    
    private var exerciseList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("CONTENIDO DE LA RUTINA")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle((colorScheme == .dark ? Color.white : Color.black).opacity(0.4))
                Spacer()
                Text("\(routine.exercises.count) EJERCICIOS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.performanceBlue)
            }
            .padding(.bottom, 4)
            
            ForEach(routine.exercises) { exercise in
                Button {
                    selectedExercise = exercise
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(exercise.name)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                            Text(exercise.technicalDescription ?? "Ejercicio de movilidad")
                                .font(.system(size: 11))
                                .foregroundStyle((colorScheme == .dark ? Color.white : Color.black).opacity(0.5))
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 0) {
                            Text("\(exercise.sets)x\(exercise.reps)")
                                .font(.system(size: 15, weight: .black, design: .monospaced))
                                .foregroundStyle(AppTheme.performanceBlue)
                            Text("SERIES")
                                .font(.system(size: 7, weight: .black))
                                .foregroundStyle(AppTheme.performanceBlue.opacity(0.6))
                        }
                    }
                    .padding(14)
                    .background(AppTheme.glassBackground(for: colorScheme))
                    .glassCard(cornerRadius: 12)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var startSessionButton: some View {
        VStack {
            Spacer()
            Button {
                showCheckin = true
            } label: {
                HStack(spacing: 12) {
                    Text("INICIAR ENTRENAMIENTO")
                    Image(systemName: "play.fill")
                }
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(AppTheme.athleteOrange.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .premiumShadow()
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Iniciar Entrenamiento, fase \(routine.dayTitle)")
                .accessibilityHint("Abre el formulario de Check-in para evaluar tu dolor antes de empezar")
                .accessibilityAddTraits(.isButton)
            }
            .padding(24)
            .background(
                AppTheme.adaptiveBackground(for: colorScheme)
                    .opacity(0.9)
                    .blur(radius: 10)
                    .ignoresSafeArea()
            )
        }
    }
    
    /// Modifica los ejercicios en tiempo real cortando volumen y series si el paciente reporta dolor agudo severo.
    private func scaleDownRoutineForPain() {
        let context = routine.modelContext
        for exercise in routine.exercises {
            // Cortamos repeticiones a la mitad
            exercise.reps = max(1, Int(Double(exercise.reps) * 0.5))
            // Quitamos una serie completa para aligerar la carga mecánica
            exercise.sets = max(1, exercise.sets - 1)
        }
        try? context?.save()
    }
}
