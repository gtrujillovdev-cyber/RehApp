import Foundation
import SwiftData

/// Modelo que representa un ejercicio individual dentro de una rutina de rehabilitación.
/// Utiliza @Model para la persistencia automática con SwiftData.
@Model
final class Exercise {
    var id: UUID
    var name: String // Nombre del ejercicio (ej. "Sentadilla Isométrica")
    var reps: Int // Número de repeticiones
    var sets: Int // Número de series
    var animationModelID: String // Identificador para la animación 3D o video
    var isCompleted: Bool // Estado de finalización para seguimiento de progreso
    var technicalDescription: String? // Explicación clínica del objetivo del ejercicio
    var instructions: [String]? // Pasos detallados para realizar el ejercicio correctamente
    var pointsReward: Int? // Puntos que otorga al completarse (Gamificación)
    var estimatedDurationPerRep: TimeInterval? // Tiempo estimado por repetición para el cronómetro
    
    // Relación opcional con la rutina diaria a la que pertenece
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
