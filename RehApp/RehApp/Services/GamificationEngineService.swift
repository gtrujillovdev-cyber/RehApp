import Foundation
import SwiftData

@MainActor
protocol GamificationEngineServiceProtocol: Sendable {
    func processExerciseCompletion(
        exercise: Exercise,
        profile: InjuryProfile,
        repository: RecoveryRepositoryProtocol
    ) async throws -> [Milestone]
}

/// Servicio de gamificación: suma puntos, actualiza rachas y desbloquea hitos.
///
/// Flujo de datos:
///   exercise completado → puntos sumados al perfil → comparar score contra catálogo
///   de hitos → desbloquear los que superen el umbral → persistir todo.
@MainActor
final class GamificationEngineService: GamificationEngineServiceProtocol {

    func processExerciseCompletion(
        exercise: Exercise,
        profile: InjuryProfile,
        repository: RecoveryRepositoryProtocol
    ) async throws -> [Milestone] {
        // Guard-early-return: si ya está completado no hacemos nada.
        // Es mejor retornar vacío que lanzar un error aquí; completar algo ya hecho
        // no es un error del sistema, es una operación idempotente.
        guard !exercise.isCompleted else { return [] }

        // 1. Marcar el ejercicio como completado
        exercise.isCompleted = true

        // 2. Sumar la recompensa de puntos al perfil
        profile.recoveryScore += exercise.pointsReward ?? 0

        // 3. Actualizar la racha comparando fechas (no contando ejercicios)
        let now = Date()
        profile.currentStreak = GamificationEngineService.calculateStreak(
            currentStreak: profile.currentStreak,
            lastSessionDate: profile.lastSessionDate,
            now: now
        )
        profile.lastSessionDate = now

        // 4. Comprobar qué hitos se desbloquean con la nueva puntuación
        let newlyUnlocked = try checkAndUnlockMilestones(for: profile, repository: repository)

        // 5. Persistir todos los cambios (perfil + hitos) en un solo save
        // Por qué un solo save: SwiftData agrupa los cambios pendientes en el contexto
        // y los escribe en una transacción atómica. Múltiples saves = múltiples transacciones
        // = riesgo de estado inconsistente si uno falla a mitad.
        try repository.saveInjuryProfile(profile)

        return newlyUnlocked
    }

    // MARK: - Lógica de desbloqueo

    /// Compara el score actual del perfil con el catálogo de hitos y desbloquea
    /// los que el usuario acaba de superar.
    ///
    /// Por qué `Set<UUID>` para `alreadyUnlocked`:
    /// Si usáramos un array, comprobar si un hito ya está desbloqueado costaría O(n)
    /// por cada hito del catálogo — O(n²) en total. Con un Set la búsqueda es O(1),
    /// así que el total es O(n) independientemente del tamaño del catálogo.
    private func checkAndUnlockMilestones(
        for profile: InjuryProfile,
        repository: RecoveryRepositoryProtocol
    ) throws -> [Milestone] {
        let allMilestones = try repository.fetchMilestones()

        // Construimos un Set con los IDs de hitos ya desbloqueados por este perfil
        let alreadyUnlockedIDs = Set(profile.unlockedMilestones.map { $0.id })

        // Filtramos: solo los que superen el umbral Y que no estén ya desbloqueados
        let newlyUnlocked = allMilestones.filter { milestone in
            !alreadyUnlockedIDs.contains(milestone.id) &&
            profile.recoveryScore >= milestone.requiredScore
        }

        let unlockDate = Date()
        for milestone in newlyUnlocked {
            milestone.isUnlocked = true
            milestone.unlockedAt = unlockDate
            // Registrar en la relación muchos-a-muchos del perfil.
            // SwiftData actualiza automáticamente el lado inverso
            // (milestone.unlockedByProfiles incluirá al perfil).
            profile.unlockedMilestones.append(milestone)
        }

        return newlyUnlocked
    }

    // MARK: - Cálculo de racha (función pura y testeable)

    /// Devuelve el nuevo valor de la racha comparando la fecha de la última sesión con `now`.
    ///
    /// Por qué esta función es `internal static` y acepta `now`:
    /// - `static`: no necesita estado del servicio, es lógica pura.
    /// - `internal` (acceso por defecto): los tests del módulo pueden llamarla directamente
    ///   con cualquier fecha, sin necesitar mocks ni inyección de dependencias.
    /// - `now: Date = Date()`: en producción se usa la fecha real; en tests se pasa
    ///   una fecha conocida para controlar exactamente qué escenario se está probando.
    ///
    /// Los 4 escenarios posibles:
    ///   1. Sin sesión previa   → primera vez            → racha = 1
    ///   2. Última sesión = hoy → ya se contó este día   → racha sin cambios (idempotente)
    ///   3. Última sesión = ayer → día consecutivo       → racha + 1
    ///   4. Última sesión = hace 2+ días → racha rota    → racha = 1
    static func calculateStreak(
        currentStreak: Int,
        lastSessionDate: Date?,
        now: Date = Date()
    ) -> Int {
        let calendar = Calendar.current

        guard let last = lastSessionDate else {
            return 1  // Escenario 1: primera sesión de siempre
        }

        if calendar.isDate(last, inSameDayAs: now) {
            return currentStreak  // Escenario 2: ya completó algo hoy
        }

        // Calculamos "ayer" relativo a `now` (no al reloj del sistema)
        // para que los tests con fechas artificiales funcionen correctamente
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(last, inSameDayAs: yesterday) {
            return currentStreak + 1  // Escenario 3: día consecutivo
        }

        return 1  // Escenario 4: hubo un hueco de 2+ días
    }
}
