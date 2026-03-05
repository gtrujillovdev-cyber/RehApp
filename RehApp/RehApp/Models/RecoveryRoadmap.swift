import Foundation
import SwiftData

/// Modelo que representa la hoja de ruta completa de recuperación generada por la IA.
@Model
final class RecoveryRoadmap {
    var id: UUID
    var createdAt: Date // Fecha de creación del plan
    var estimatedWeeks: Int // Duración total estimada del plan
    var aiReasoning: String? // Explicación textual de la IA sobre por qué se ha generado este plan
    
    // Relación inversa con el perfil de lesión
    var injuryProfile: InjuryProfile?
    
    // Relación de uno a muchos con las fases de recuperación
    @Relationship(deleteRule: .cascade)
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

/// Representa una etapa específica dentro del proceso de recuperación (ej. "Fase de Movilidad").
@Model
final class RecoveryPhase {
    var id: UUID
    var title: String // Título de la fase
    var phaseDescription: String // Qué se espera lograr en esta fase
    var order: Int // Orden cronológico de la fase (1, 2, 3...)
    
    // Relación con el roadmap padre
    var roadmap: RecoveryRoadmap?
    
    // Relación con las rutinas diarias que componen la fase
    @Relationship(deleteRule: .cascade)
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
    var dayTitle: String // Título del día (ej. "Lunes (Semana 1)")
    var order: Int // Orden dentro de la fase
    
    // Relación con la fase a la que pertenece
    var phase: RecoveryPhase?
    
    // Relación con los ejercicios que se deben realizar ese día
    @Relationship(deleteRule: .cascade)
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
