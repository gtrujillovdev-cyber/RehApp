import Foundation
import SwiftData

/// Modelo central que representa el perfil de lesión de un usuario.
/// Este es el punto de entrada para generar la hoja de ruta de recuperación.
@Model
final class InjuryProfile: Identifiable {
    var id: UUID
    var bodyPart: String // Parte del cuerpo afectada (ej. "Rodilla")
    var painLevel: Int // Nivel de dolor del 1 al 10 reportado por el usuario
    var sport: String // Deporte principal para adaptar los ejercicios finales
    var symptomsDescription: String // Descripción de los síntomas actuales
    var medicalReportText: String? // Texto extraído de informes médicos mediante OCR o escaneo
    var injuryDate: Date // Fecha en que ocurrió la lesión
    var recoveryScore: Int // Puntos acumulados (Gamificación)
    var currentStreak: Int // Racha de días consecutivos completando rutinas
    
    // Preferencias del usuario para la generación del plan
    var daysPerWeek: Int = 3
    var exercisesPerDay: Int = 2
    var targetDuration: Int = 15 // Duración objetivo de la sesión en minutos
    
    // Relación de uno a muchos con las hojas de ruta generadas
    // .cascade asegura que si se borra el perfil, se borren sus roadmaps
    @Relationship(deleteRule: .cascade, inverse: \RecoveryRoadmap.injuryProfile)
    var roadmaps: [RecoveryRoadmap] = []
    
    init(
        id: UUID = UUID(),
        bodyPart: String,
        painLevel: Int,
        sport: String,
        symptomsDescription: String,
        medicalReportText: String? = nil,
        injuryDate: Date = Date(),
        recoveryScore: Int = 0,
        currentStreak: Int = 0,
        daysPerWeek: Int = 3,
        exercisesPerDay: Int = 2,
        targetDuration: Int = 15
    ) {
        self.id = id
        self.bodyPart = bodyPart
        self.painLevel = painLevel
        self.sport = sport
        self.symptomsDescription = symptomsDescription
        self.medicalReportText = medicalReportText
        self.injuryDate = injuryDate
        self.recoveryScore = recoveryScore
        self.currentStreak = currentStreak
        self.daysPerWeek = daysPerWeek
        self.exercisesPerDay = exercisesPerDay
        self.targetDuration = targetDuration
    }
}
