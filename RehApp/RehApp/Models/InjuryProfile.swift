import Foundation
import SwiftData

/// Modelo central que representa el perfil de lesión de un usuario.
/// Este es el punto de entrada para generar la hoja de ruta de recuperación.
///
/// Por qué `@Attribute(.unique)` en `id`:
/// Sin esta anotación, SQLite no tiene restricción UNIQUE sobre esa columna,
/// lo que permite insertar filas duplicadas silenciosamente. Con ella, SwiftData
/// puede usar semántica de upsert: si ya existe un perfil con ese UUID, lo
/// actualiza en lugar de duplicarlo.
///
/// Por qué ya no está `: Identifiable`:
/// `var id: UUID` satisface automáticamente el protocolo `Identifiable` en Swift
/// (cualquier tipo con `var id` cumple el requisito). Declararlo explícitamente
/// era redundante e inconsistente con el resto de modelos de la app.
@Model
final class InjuryProfile {
    @Attribute(.unique) var id: UUID
    var bodyPart: String        // Parte del cuerpo afectada (ej. "Rodilla")
    var painLevel: Int          // Nivel de dolor del 1 al 10 reportado por el usuario
    var sport: String           // Deporte principal para adaptar los ejercicios finales
    var symptomsDescription: String // Descripción de los síntomas actuales
    var medicalReportText: String?  // Texto extraído de informes médicos mediante OCR
    var injuryDate: Date        // Fecha en que ocurrió la lesión
    var recoveryScore: Int      // Puntos acumulados (Gamificación)
    var currentStreak: Int      // Racha de días consecutivos completando rutinas
    /// Fecha de la última sesión completada.
    /// Necesaria para calcular si la racha sigue activa, se incrementa o se rompe.
    /// Sin este campo es imposible distinguir "completé 5 ejercicios hoy" de
    /// "completé 1 ejercicio durante 5 días seguidos".
    var lastSessionDate: Date?

    // Preferencias del usuario para la generación del plan
    var daysPerWeek: Int = 3
    var exercisesPerDay: Int = 2
    var targetDuration: Int = 15    // Duración objetivo de la sesión en minutos

    // MARK: - Relaciones

    /// Uno a muchos: un perfil puede tener varias hojas de ruta generadas.
    /// `.cascade` → al borrar el perfil, se borran todos sus roadmaps.
    /// `inverse:` → le dice a SwiftData qué propiedad de RecoveryRoadmap
    /// forma la otra mitad de esta relación, evitando columnas duplicadas en SQLite.
    @Relationship(deleteRule: .cascade, inverse: \RecoveryRoadmap.injuryProfile)
    var roadmaps: [RecoveryRoadmap] = []

    /// Muchos a muchos: un perfil puede desbloquear varios hitos,
    /// y el mismo hito puede ser desbloqueado por perfiles distintos.
    ///
    /// Por qué `.nullify` y no `.cascade`:
    /// Los hitos son definiciones del catálogo de la app, no datos del usuario.
    /// Al borrar un perfil solo queremos eliminar la asociación (la fila en la
    /// tabla intermedia), no destruir la definición del hito que otros perfiles
    /// podrían referenciar.
    @Relationship(deleteRule: .nullify, inverse: \Milestone.unlockedByProfiles)
    var unlockedMilestones: [Milestone] = []

    /// Historial de actividad del usuario.
    @Relationship(deleteRule: .cascade, inverse: \ActivityLog.injuryProfile)
    var activityLogs: [ActivityLog] = []

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
