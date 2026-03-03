import SwiftUI

struct SessionOverviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let routine: DailyRoutine
    let profile: InjuryProfile
    let repository: RecoveryRepositoryProtocol
    
    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.adaptiveBackground(for: colorScheme).ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerBar
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        sessionInfoCard
                        
                        exerciseList
                        
                        // Extra space for the button
                        Color.clear.frame(height: 120)
                    }
                    .padding(24)
                }
            }
            
            startSessionButton
        }
        .navigationBarBackButtonHidden()
    }
    
    private var headerBar: some View {
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
            
            Text("DETALLE DE SESIÓN")
                .font(.system(size: 12, weight: .black))
                .tracking(2)
                .foregroundStyle(colorScheme == .dark ? .white.opacity(0.4) : .black.opacity(0.4))
            
            Spacer()
            
            // Empty placeholder for balance
            Color.clear.frame(width: 42)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var sessionInfoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(routine.dayTitle.uppercased())
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(AppTheme.athleteOrange)
            
            Text("Preparación Clínica")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(colorScheme == .dark ? .white : .black)
            
            Text("Esta sesión está diseñada para la \(routine.phase?.title.lowercased() ?? "fase de recuperación"). Céntrate en la calidad técnica de cada movimiento.")
                .font(.system(size: 15))
                .foregroundStyle((colorScheme == .dark ? Color.white : Color.black).opacity(0.6))
                .lineSpacing(4)
        }
    }
    
    private var exerciseList: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("CONTENIDO DE LA RUTINA")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle((colorScheme == .dark ? Color.white : Color.black).opacity(0.4))
                Spacer()
                Text("\(routine.exercises.count) EJERCICIOS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.performanceBlue)
            }
            
            ForEach(routine.exercises) { exercise in
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.name)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                        Text(exercise.technicalDescription ?? "Ejercicio de movilidad")
                            .font(.system(size: 12))
                            .foregroundStyle((colorScheme == .dark ? Color.white : Color.black).opacity(0.5))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(exercise.sets)x\(exercise.reps)")
                            .font(.system(size: 16, weight: .black, design: .monospaced))
                            .foregroundStyle(AppTheme.performanceBlue)
                        Text("SERIES")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(AppTheme.performanceBlue.opacity(0.6))
                    }
                }
                .padding(20)
                .background(AppTheme.glassBackground(for: colorScheme))
                .glassCard(cornerRadius: 20)
            }
        }
    }
    
    private var startSessionButton: some View {
        VStack {
            Spacer()
            NavigationLink {
                ExercisePlayerView(viewModel: ExercisePlayerViewModel(
                    sessionBlocks: routine.exercises.map { .exercise($0) },
                    profile: profile,
                    repository: repository
                ))
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
}
