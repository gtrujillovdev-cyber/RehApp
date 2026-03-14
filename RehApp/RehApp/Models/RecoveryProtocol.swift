import Foundation

/// Representa un protocolo clínico completo para una patología específica (ej. Condromalacia)
struct ClinicalProtocol: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let phases: [ClinicalRecoveryPhase]
}

/// Representa una fase de recuperación clínica (ej. Fase 1: Aguda)
struct ClinicalRecoveryPhase: Codable, Identifiable {
    let phaseId: Int
    let name: String
    let objective: String
    let recommendedDurationDays: Int
    let exercises: [ClinicalExercise]
    
    var id: Int { phaseId }
}

/// Ejercicio prescrito dentro del protocolo clínico
struct ClinicalExercise: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let sets: Int
    let reps: Int
    let holdSeconds: Int
    let videoURL: String?
    let isBilateral: Bool
}
