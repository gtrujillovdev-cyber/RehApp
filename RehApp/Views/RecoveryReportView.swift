import SwiftUI

struct RecoveryReportView: View {
    @Environment(\.colorScheme) private var colorScheme
    let profile: InjuryProfile
    let roadmap: RecoveryRoadmap
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                headerSection
                
                // AI Reasoning Block
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.athleteOrange)
                        Text("ANÁLISIS DE ESTRATEGIA IA")
                            .font(.system(size: 11, weight: .black))
                            .tracking(1.2)
                            .foregroundStyle(AppTheme.athleteOrange)
                    }
                    
                    Text(roadmap.aiReasoning ?? "Analizando patrones de recuperación funcional para tu lesión de \(profile.bodyPart)...")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                        .lineSpacing(6)
                        .padding(24)
                        .background(
                            ZStack {
                                AppTheme.athleteOrange.opacity(0.04)
                                AppTheme.glassBackground(for: colorScheme)
                            }
                        )
                        .glassCard(cornerRadius: 28)
                }
                
                // Strategy Matrix
                VStack(alignment: .leading, spacing: 20) {
                    Text("HOJA DE RUTA GENERADA")
                        .font(.system(size: 11, weight: .black))
                        .tracking(1.2)
                        .foregroundStyle(AppTheme.performanceBlue)
                        .padding(.horizontal, 4)
                    
                    VStack(spacing: 16) {
                        ForEach(Array(roadmap.phases.sorted(by: { $0.order < $1.order }).enumerated()), id: \.element.id) { index, phase in
                            PhaseDetailCard(
                                phase: phase,
                                color: index % 2 == 0 ? AppTheme.performanceBlue : .green
                            )
                        }
                    }
                }
                
                // Safety & Ethics
                VStack(alignment: .leading, spacing: 16) {
                    Label {
                        Text("PROTOCOLO DE SEGURIDAD")
                            .font(.system(size: 11, weight: .black))
                            .tracking(1.2)
                            .foregroundStyle(.red)
                    } icon: {
                        Image(systemName: "exclamationmark.shield.fill")
                            .foregroundStyle(.red)
                    }
                    
                    VStack(alignment: .leading, spacing: 14) {
                        SafetyRow(text: "No superar el grado 3 de dolor en la escala EVA.")
                        SafetyRow(text: "Suspender actividad si aparece inflamación aguda.")
                        SafetyRow(text: "Respetar tiempos de descanso entre series mecánicas.")
                    }
                    .padding(24)
                    .background(Color.red.opacity(0.05))
                    .glassCard(cornerRadius: 28)
                }
                
                Color.clear.frame(height: 60)
            }
            .padding(24)
        }
        .background((colorScheme == .dark ? AppTheme.deepSlate : Color(white: 0.95)).ignoresSafeArea())
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Estrategia Clínica")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(colorScheme == .dark ? .white : .black)
            
            HStack(spacing: 12) {
                Text(profile.bodyPart.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.performanceBlue)
                
                Text("|")
                    .foregroundStyle(AppTheme.tertiaryText(for: colorScheme).opacity(0.5))
                
                Text(profile.sport.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
            }
        }
    }
}

struct PhaseDetailCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let phase: RecoveryPhase
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            VStack {
                Text("\(phase.order)")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(color.gradient)
                    .clipShape(Circle())
                
                Rectangle()
                    .fill(color.opacity(0.2))
                    .frame(width: 2)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(phase.title.replacingOccurrences(of: "Fase \(phase.order): ", with: "").uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                
                Text(phase.phaseDescription)
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                    .lineSpacing(4)
                
                Text("\(phase.dailyRoutines.count) rutinas diseñadas")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(color.opacity(0.8))
                    .padding(.top, 4)
            }
            .padding(.bottom, 16)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.glassBackground(for: colorScheme))
        .glassCard(cornerRadius: 24)
    }
}

struct SafetyRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundStyle(.red.opacity(0.6))
                .padding(.top, 6)
            
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
        }
    }
}
