import Foundation
import SwiftData

/// Modelo que representa un ejercicio individual dentro de una rutina de rehabilitación.
@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String                        // Nombre del ejercicio (ej. "Sentadilla Isométrica")
    var reps: Int                           // Número de repeticiones
    var sets: Int                           // Número de series
    var animationModelID: String            // Identificador para la animación 3D o video
    var isCompleted: Bool                   // Estado de finalización para seguimiento de progreso
    var technicalDescription: String?       // Explicación clínica del objetivo del ejercicio
    /// Nota: `[String]` se serializa como JSON en SQLite (Transformable).
    /// No es posible filtrar por instrucciones individuales con un Predicate.
    /// Si en el futuro se necesita ordenarlas o buscar por ellas, modelar como @Model separado.
    var instructions: [String]?
    var pointsReward: Int?                  // Puntos que otorga al completarse (Gamificación)
    var estimatedDurationPerRep: TimeInterval? // Tiempo estimado por repetición para el cronómetro

    /// Lado inverso de la relación con DailyRoutine.
    /// No lleva `@Relationship` propio: la relación ya está declarada y gestionada
    /// desde el lado padre (`DailyRoutine.exercises`) con `inverse: \Exercise.routine`.
    /// SwiftData usa esta propiedad solo como referencia de navegación.
    var routine: DailyRoutine?

    init(
        id: UUID = UUID(),
        name: String,
        reps: Int,
        sets: Int,
        animationModelID: String,
        technicalDescription: String = "",
        instructions: [String] = [],
        isCompleted: Bool = false,
        pointsReward: Int = 10,
        estimatedDurationPerRep: TimeInterval? = nil
    ) {
        self.id = id
        self.name = name
        self.reps = reps
        self.sets = sets
        self.animationModelID = animationModelID
        self.technicalDescription = technicalDescription
        self.instructions = instructions
        self.isCompleted = isCompleted
        self.pointsReward = pointsReward
        self.estimatedDurationPerRep = estimatedDurationPerRep
    }
}
