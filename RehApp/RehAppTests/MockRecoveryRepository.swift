import Foundation
@testable import RehApp

/// Implementación falsa del repositorio para tests unitarios.
///
/// Por qué necesitamos esto cuando ya existe RecoveryRepository con SwiftData in-memory:
///
/// 1. VELOCIDAD — SwiftData in-memory sigue necesitando inicializar el stack completo
///    (ModelContainer, ModelContext, schema). Con este mock el setup es instantáneo.
///
/// 2. CONTROL DE ERRORES — SwiftData in-memory no falla bajo demanda. No hay forma
///    de decirle "lanza un error en el próximo fetch". Con shouldThrowOnFetch = true
///    podemos testear exactamente qué hace el ViewModel cuando la base de datos falla.
///
/// 3. ESPÍAS (Spies) — Podemos verificar que el servicio llamó al repositorio exactamente
///    el número de veces correcto, con el argumento correcto. SwiftData no expone eso.
///
/// 4. AISLAMIENTO — Los tests de ViewModel no deben saber nada de SwiftData.
///    Si mañana cambiamos de SwiftData a otro ORM, los tests de ViewModel no cambian.
@MainActor
final class MockRecoveryRepository: RecoveryRepositoryProtocol {

    // MARK: - Estado interno (la "base de datos" en memoria)
    var storedProfiles: [InjuryProfile] = []
    var storedMilestones: [Milestone] = []

    // MARK: - Espías (registran cada llamada para aserciones en los tests)
    private(set) var saveProfileCallCount    = 0
    private(set) var deleteProfileCallCount  = 0
    private(set) var fetchProfilesCallCount  = 0
    private(set) var fetchMilestonesCallCount = 0
    private(set) var lastSavedProfile: InjuryProfile?
    private(set) var lastDeletedProfile: InjuryProfile?

    // MARK: - Simulación de fallos
    /// Activar a true para testear el error handling del código que llama al repositorio.
    var shouldThrowOnSave  = false
    var shouldThrowOnFetch = false

    // MARK: - RecoveryRepositoryProtocol

    func saveInjuryProfile(_ profile: InjuryProfile) throws {
        if shouldThrowOnSave { throw MockRepositoryError.forcedFailure }
        saveProfileCallCount += 1
        lastSavedProfile = profile
        // Upsert: añade si no existe, ignora si ya está (mismo comportamiento que @Attribute(.unique))
        if !storedProfiles.contains(where: { $0.id == profile.id }) {
            storedProfiles.append(profile)
        }
    }

    func deleteInjuryProfile(_ profile: InjuryProfile) throws {
        deleteProfileCallCount += 1
        lastDeletedProfile = profile
        storedProfiles.removeAll { $0.id == profile.id }
    }

    func fetchInjuryProfiles() throws -> [InjuryProfile] {
        if shouldThrowOnFetch { throw MockRepositoryError.forcedFailure }
        fetchProfilesCallCount += 1
        return storedProfiles
    }

    func saveRecoveryRoadmap(_ roadmap: RecoveryRoadmap) throws {
        if shouldThrowOnSave { throw MockRepositoryError.forcedFailure }
    }

    func fetchMilestones() throws -> [Milestone] {
        fetchMilestonesCallCount += 1
        // Misma ordenación que el repositorio real
        return storedMilestones.sorted { $0.requiredScore < $1.requiredScore }
    }

    // MARK: - Error simulado

    enum MockRepositoryError: Error, LocalizedError {
        case forcedFailure
        var errorDescription: String? { "Error simulado para tests" }
    }
}
