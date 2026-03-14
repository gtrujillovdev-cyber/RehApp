import Foundation
import SwiftData

/// Modelo que representa un ejercicio individual dentro de una rutina de rehabilitación.
@Model
final class Exercise {
    var id: UUID
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

extension Exercise {
    /// Resuelve el nombre del recurso de imagen (Asset) basándose en el nombre o animationModelID.
    /// Garantiza que se use el prefijo 'exercise_' que es el estándar del catálogo de assets.
    var imageResourceName: String {
        // Si el ID ya trae el prefijo, lo usamos
        if animationModelID.hasPrefix("exercise_") {
            return animationModelID
        }
        
        // Mapeo inteligente por palabras clave (similar a ExerciseDetailView)
        let normalized = name.lowercased()
        
        if normalized.contains("sentadilla") || normalized.contains("squat") {
            return "exercise_squat"
        } else if normalized.contains("plancha") || normalized.contains("plank") || normalized.contains("core") || normalized.contains("abdominal") {
            return "exercise_plank"
        } else if normalized.contains("puente") || normalized.contains("bridge") || normalized.contains("glúteo") {
            return "exercise_bridge"
        } else if normalized.contains("extensión") || normalized.contains("tqe") || normalized.contains("flexo") {
            return "exercise_tqe"
        } else if normalized.contains("clamshell") || normalized.contains("almeja") {
            return "exercise_clamshell"
        } else if normalized.contains("elevación") || normalized.contains("recta") || normalized.contains("leg raise") {
            return "exercise_leg_raise"
        } else if normalized.contains("hombro") || normalized.contains("rotador") || normalized.contains("rotación") || normalized.contains("shoulder") {
            return "exercise_shoulder"
        } else if normalized.contains("cuello") || normalized.contains("cervical") || normalized.contains("neck") {
            return "exercise_neck"
        } else if normalized.contains("espalda") || normalized.contains("lumbar") || normalized.contains("dorsal") {
            return "exercise_back"
        } else if normalized.contains("tobillo") || normalized.contains("gemelo") || normalized.contains("ankle") {
            return "exercise_ankle"
        } else if normalized.contains("muñeca") || normalized.contains("wrist") || normalized.contains("supinación") {
            return "exercise_wrist"
        } else if normalized.contains("pectoral") || normalized.contains("chest") {
            return "exercise_chest"
        } else if normalized.contains("dead bug") || normalized.contains("plancha lateral") || normalized.contains("core stability") {
            return "exercise_core_adv"
        } else if normalized.contains("zancada") || normalized.contains("lunge") || normalized.contains("búlgara") || normalized.contains("peso muerto") {
            return "exercise_lunge"
        } else if normalized.contains("bíceps") || normalized.contains("tríceps") || normalized.contains("bicep") {
            return "exercise_arm"
        }
        
        // Fallback: intentar concatenar el prefijo directamente al ID original
        return "exercise_\(animationModelID)"
    }
}
