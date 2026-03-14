import SwiftUI
import SwiftData

struct DailyCheckinView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let routine: DailyRoutine
    var onComplete: (Int) -> Void

    @State private var painLevel: Double = 5.0
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Revisión Diaria")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .padding(.top, 40)
            
            Text("¿Qué nivel de molestia sientes hoy antes de entrenar?")
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            Spacer()
            
            Text("\(Int(painLevel))")
                .font(.system(size: 80, weight: .black, design: .rounded))
                .foregroundStyle(colorForPain(Int(painLevel)))
            
            Slider(value: $painLevel, in: 1...10, step: 1)
                .tint(colorForPain(Int(painLevel)))
                .padding(.horizontal, 40)
            
            HStack {
                Text("Casi nada (1)")
                Spacer()
                Text("Agotador (10)")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 40)
            
            Spacer()
            
            if Int(painLevel) >= 8 {
                Text("Avisaremos al sistema para reducir la intensidad de carga hoy.")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            
            Button {
                let context = routine.modelContext
                routine.reportedPainLevel = Int(painLevel)
                try? context?.save()
                onComplete(Int(painLevel))
            } label: {
                HStack {
                    Text("Confirmar y Empezar")
                    Image(systemName: "checkmark.circle.fill")
                }
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppTheme.athleteOrange.gradient)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .premiumShadow()
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
        .background(AppTheme.adaptiveBackground(for: colorScheme))
        .interactiveDismissDisabled()
    }
    
    private func colorForPain(_ level: Int) -> Color {
        switch level {
        case 1...3: return .green
        case 4...6: return .yellow
        case 7...10: return .red
        default: return AppTheme.athleteOrange
        }
    }
}
