import Foundation
import SwiftData

/// Protocolo para el motor de gamificación.
@MainActor
protocol GamificationEngineServiceProtocol: Sendable {
    func processExerciseCompletion(exercise: Exercise, profile: InjuryProfile, repository: RecoveryRepositoryProtocol) async throws -> [Milestone]
}

/// Servicio encargado de gestionar el progreso, puntos y logros del usuario.
/// Fomenta la adherencia al tratamiento mediante sistemas de recompensa.
@MainActor
final class GamificationEngineService: GamificationEngineServiceProtocol {
    
    /// Procesa la finalización de un ejercicio, suma puntos y actualiza la racha.
    /// - Returns: Una lista de nuevos hitos desbloqueados si los hay.
    func processExerciseCompletion(exercise: Exercise, profile: InjuryProfile, repository: RecoveryRepositoryProtocol) async throws -> [Milestone] {
        guard !exercise.isCompleted else { return [] }
        
        // 1. Marcar como completado
        exercise.isCompleted = true
        
        // 2. Sumar puntos al perfil global del usuario
        profile.recoveryScore += exercise.pointsReward ?? 0
        
        // 3. Incrementar la racha (Streak)
        profile.currentStreak += 1
        
        // 4. Persistir los cambios en SwiftData
        try? repository.saveInjuryProfile(profile)
        
        // Nota: En futuras versiones se añadiría aquí la lógica para comprobar hitos desbloqueados
        return []
    }
}
