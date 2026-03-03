import SwiftUI

struct ClinicalAdviceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            AppTheme.adaptiveBackground(for: colorScheme).ignoresSafeArea()
            
            VStack(spacing: 32) {
                HStack {
                    Text("Guía Clínica de Seguridad")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle((colorScheme == .dark ? Color.white : Color.black).opacity(0.3))
                    }
                }
                .padding(.top, 40)
                
                VStack(alignment: .leading, spacing: 24) {
                    AdviceCard(icon: "checkmark.shield.fill", title: "Regla de Oro", description: "El dolor no debe superar el nivel 3/10. Si sientes un pinchazo agudo, detén el ejercicio inmediatamente.", color: AppTheme.athleteOrange)
                    
                    AdviceCard(icon: "figure.walk", title: "Control Motor", description: "La calidad del movimiento supera a la cantidad. Mantén la velocidad controlada y respira rítmicamente.", color: AppTheme.performanceBlue)
                    
                    AdviceCard(icon: "exclamationmark.triangle.fill", title: "Señales de Alerta", description: "Inflamación, calor excesivo en la zona o pérdida de sensibilidad son motivos para consultar con tu fisioterapeura.", color: .red)
                }
                
                Spacer()
                
                Button("ENTENDIDO") { dismiss() }
                    .buttonStyle(PremiumButtonStyle())
            }
            .padding(32)
        }
    }
}

struct AdviceCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(color)
                Text(description)
                    .font(.system(size: 14))
                    .foregroundStyle((colorScheme == .dark ? Color.white : Color.black).opacity(0.8))
                    .lineSpacing(4)
            }
        }
        .padding(24)
        .background(AppTheme.glassBackground(for: colorScheme))
        .glassCard(cornerRadius: 24)
    }
}

struct WorkoutSummaryView: View {
    @Environment(\.colorScheme) private var colorScheme
    let score: Int
    let onDone: () -> Void
    
    var body: some View {
        ZStack {
            AppTheme.adaptiveBackground(for: colorScheme).ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(AppTheme.athleteOrange.opacity(0.1))
                        .frame(width: 200, height: 200)
                    
                    VStack(spacing: 0) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(AppTheme.athleteOrange.gradient)
                        Text("SESIÓN COMPLETADA")
                            .font(.system(size: 10, weight: .black))
                            .tracking(2)
                            .foregroundStyle(AppTheme.athleteOrange)
                            .padding(.top, 20)
                    }
                }
                
                VStack(spacing: 12) {
                    Text("¡Excelente trabajo!")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                    
                    Text("Has sumado puntos a tu racha de recuperación.")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                HStack(spacing: 20) {
                    SummaryMetric(label: "SCORE", value: "+\(score)", icon: "star.fill", color: .yellow)
                    SummaryMetric(label: "TIEMPO", value: "12m", icon: "clock.fill", color: AppTheme.performanceBlue)
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                Button("FINALIZAR") { onDone() }
                    .buttonStyle(PremiumButtonStyle())
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
            }
        }
    }
}

struct SummaryMetric: View {
    @Environment(\.colorScheme) private var colorScheme
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(colorScheme == .dark ? .white : .black)
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle((colorScheme == .dark ? Color.white : Color.black).opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(AppTheme.glassBackground(for: colorScheme))
        .glassCard(cornerRadius: 24)
    }
}
