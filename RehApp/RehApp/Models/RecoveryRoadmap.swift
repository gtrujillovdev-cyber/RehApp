import Foundation
import SwiftData

/// Modelo que representa la hoja de ruta completa de recuperación generada por la IA.
///
/// La jerarquía completa es:
///   InjuryProfile → [RecoveryRoadmap] → [RecoveryPhase] → [DailyRoutine] → [Exercise]
/// Cada nivel tiene `deleteRule: .cascade` con `inverse:` explícito para que SwiftData
/// represente cada relación como UNA sola columna en SQLite (no dos).
@Model
final class RecoveryRoadmap {
    var id: UUID
    var createdAt: Date     // Fecha de creación del plan
    var estimatedWeeks: Int // Duración total estimada del plan
    var aiReasoning: String? // Explicación textual de la IA sobre este plan
    var currentPhaseIndex: Int = 0 // Índice de la fase actual (1, 2, 3...)
    
    var progress: Double {
        guard !phases.isEmpty else { return 0 }
        return Double(currentPhaseIndex) / Double(phases.count)
    }

    /// Lado inverso de la relación con InjuryProfile.
    /// SwiftData gestiona esta referencia automáticamente cuando se asigna
    /// el roadmap al array `injuryProfile.roadmaps`.
    var injuryProfile: InjuryProfile?

    /// Por qué `inverse: \RecoveryPhase.roadmap`:
    /// Sin este parámetro SwiftData infiere la inversa buscando propiedades del
    /// tipo correcto en RecoveryPhase. Funciona mientras solo haya UNA propiedad
    /// de tipo `RecoveryRoadmap?` en esa clase. Si añadimos otra en el futuro
    /// (ej. `previousRoadmap`), la inferencia se vuelve ambigua y el delete cascade
    /// puede propagarse por el lado equivocado. Siendo explícitos evitamos ese riesgo.
    @Relationship(deleteRule: .cascade, inverse: \RecoveryPhase.roadmap)
    var phases: [RecoveryPhase] = []

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        estimatedWeeks: Int = 0
    ) {
        self.id = id
        self.createdAt = createdAt
        self.estimatedWeeks = estimatedWeeks
    }
}

/// Representa una etapa dentro del proceso de recuperación (ej. "Fase de Movilidad").
@Model
final class RecoveryPhase {
    var id: UUID
    var title: String           // Título de la fase
    var phaseDescription: String // Qué se espera lograr en esta fase
    var order: Int              // Orden cronológico (1, 2, 3…)

    /// Lado inverso de la relación con RecoveryRoadmap.
    var roadmap: RecoveryRoadmap?

    @Relationship(deleteRule: .cascade, inverse: \DailyRoutine.phase)
    var dailyRoutines: [DailyRoutine] = []

    init(
        id: UUID = UUID(),
        title: String,
        phaseDescription: String,
        order: Int
    ) {
        self.id = id
        self.title = title
        self.phaseDescription = phaseDescription
        self.order = order
    }
}

/// Representa un día de entrenamiento específico dentro de una fase.
@Model
final class DailyRoutine {
    var id: UUID
    var dayTitle: String    // Título del día (ej. "Lunes (Semana 1)")
    var order: Int          // Orden dentro de la fase
    var isCompleted: Bool = false // Marcador de que todo el día ha sido completado
    var reportedPainLevel: Int?   // Nivel de dolor registrado en el Check-in (1-10)

    /// Lado inverso de la relación con RecoveryPhase.
    var phase: RecoveryPhase?

    /// Por qué `inverse: \Exercise.routine`:
    /// Hace que SwiftData trate ambos lados como UNA relación bidireccional.
    /// Si un Exercise se borra de forma independiente, SwiftData sabe que debe
    /// eliminarlo también de este array (porque conoce la inversa explícita).
    /// Sin esto, la referencia en el array podría quedar como un puntero colgante.
    @Relationship(deleteRule: .cascade, inverse: \Exercise.routine)
    var exercises: [Exercise] = []

    init(
        id: UUID = UUID(),
        dayTitle: String,
        order: Int
    ) {
        self.id = id
        self.dayTitle = dayTitle
        self.order = order
    }
}
