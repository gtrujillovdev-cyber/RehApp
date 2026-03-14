import SwiftUI

struct ExerciseDetailView: View {
    let exercise: Exercise
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    private func getLocalExerciseAssetName() -> String {
        exercise.imageResourceName
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header Graphic
                    headerGraphic
                    
                    VStack(alignment: .leading, spacing: 24) {
                        // Intensity / Sets Row
                        HStack(spacing: 16) {
                            StatPill(title: "SERIES", value: "\(exercise.sets)")
                            StatPill(title: "REPS", value: "\(exercise.reps)")
                            Spacer()
                        }
                        .padding(.top, 16)
                        
                        // Technical Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DESCRIPCIÓN TÉCNICA")
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(AppTheme.athleteOrange)
                            
                            Text(exercise.technicalDescription ?? "Mantén buena postura durante la ejecución.")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                                .lineSpacing(4)
                        }
                        
                        // Step by Step Instructions
                        if let instructions = exercise.instructions, !instructions.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("INSTRUCCIONES")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundStyle(AppTheme.performanceBlue)
                                
                                ForEach(Array(instructions.enumerated()), id: \.offset) { index, instruction in
                                    HStack(alignment: .top, spacing: 12) {
                                        Circle()
                                            .fill(AppTheme.performanceBlue.opacity(0.15))
                                            .frame(width: 24, height: 24)
                                            .overlay(
                                                Text("\(index + 1)")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundStyle(AppTheme.performanceBlue)
                                            )
                                        
                                        Text(instruction)
                                            .font(.system(size: 15))
                                            .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                                            .padding(.top, 2)
                                    }
                                    .accessibilityElement(children: .combine)
                                    .accessibilityLabel("Paso \(index + 1): \(instruction)")
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(24)
                }
            }
            .background(AppTheme.adaptiveBackground(for: colorScheme).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.gray.opacity(0.5))
                    }
                    .accessibilityLabel("Cerrar detalle")
                    .accessibilityHint("Cierra la vista de detalles del ejercicio actual")
                }
            }
        }
    }
    
    private var headerGraphic: some View {
        ZStack(alignment: .bottomLeading) {
            Image(getLocalExerciseAssetName())
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .clipped()
            
            // Title overlay
            LinearGradient(
                colors: [.clear, .black.opacity(0.8)],
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(height: 200)
            
            Text(exercise.name)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(20)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Ilustración 3D del ejercicio \(exercise.name)")
        .accessibilityAddTraits(.isImage)
    }
}

struct StatPill: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppTheme.tertiaryText(for: colorScheme))
            
            Text(value)
                .font(.system(size: 20, weight: .black, design: .monospaced))
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppTheme.glassBackground(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.glassBorder(for: colorScheme), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(value)")
    }
}
