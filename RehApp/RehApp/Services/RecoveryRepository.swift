import Foundation
import SwiftData

/// El repositorio es la única capa que habla directamente con SwiftData.
/// Todo el resto de la app (ViewModels, Services) usa este protocolo.
///
/// Por qué un protocolo y no la clase directamente:
/// - Testabilidad: los tests inyectan un mock que no necesita base de datos real.
/// - Intercambiabilidad: si el día de mañana cambias de SwiftData a otro ORM,
///   solo cambias la implementación, no todos los puntos de uso.
/// - Aislamiento: el ViewModel no sabe si los datos vienen de disco, red o memoria.
@MainActor
protocol RecoveryRepositoryProtocol: Sendable {
    func saveInjuryProfile(_ profile: InjuryProfile) throws
    func deleteInjuryProfile(_ profile: InjuryProfile) throws
    func fetchInjuryProfiles() throws -> [InjuryProfile]
    func saveRecoveryRoadmap(_ roadmap: RecoveryRoadmap) throws
    /// Devuelve todos los hitos definidos en la base de datos.
    /// El GamificationEngine los usa para saber cuáles desbloquear.
    func fetchMilestones() throws -> [Milestone]
    
    /// Historial de actividad
    func saveActivityLog(_ log: ActivityLog, for profile: InjuryProfile) throws
    func fetchActivityLogs(for profileID: UUID, daysLimit: Int) throws -> [ActivityLog]
}

@MainActor
final class RecoveryRepository: RecoveryRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func saveInjuryProfile(_ profile: InjuryProfile) throws {
        context.insert(profile)
        do {
            try context.save()
        } catch {
            print("Failed to save injury profile: \(error)")
            throw error
        }
    }

    func deleteInjuryProfile(_ profile: InjuryProfile) throws {
        context.delete(profile)
        do {
            try context.save()
        } catch {
            print("Failed to delete injury profile: \(error)")
            throw error
        }
    }

    func fetchInjuryProfiles() throws -> [InjuryProfile] {
        let descriptor = FetchDescriptor<InjuryProfile>()
        do {
            return try context.fetch(descriptor)
        } catch {
            print("Failed to fetch injury profiles: \(error)")
            throw error
        }
    }

    func saveRecoveryRoadmap(_ roadmap: RecoveryRoadmap) throws {
        context.insert(roadmap)
        do {
            try context.save()
        } catch {
            print("Failed to save recovery roadmap: \(error)")
            throw error
        }
    }

    /// `FetchDescriptor<Milestone>` sin predicado devuelve todos los hitos.
    /// SwiftData traduce esto a `SELECT * FROM Milestone` en SQLite.
    /// Para ordenarlos por puntuación requerida usamos `sortBy:`.
    func fetchMilestones() throws -> [Milestone] {
        var descriptor = FetchDescriptor<Milestone>(
            sortBy: [SortDescriptor(\.requiredScore)]
        )
        // Optimización: si hay muchos hitos, limitar aquí evita cargar la tabla entera
        descriptor.fetchLimit = 100
        do {
            return try context.fetch(descriptor)
        } catch {
            print("Failed to fetch milestones: \(error)")
            throw error
        }
    }

    func saveActivityLog(_ log: ActivityLog, for profile: InjuryProfile) throws {
        log.injuryProfile = profile
        context.insert(log)
        try context.save()
    }

    func fetchActivityLogs(for profileID: UUID, daysLimit: Int) throws -> [ActivityLog] {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -daysLimit, to: Date()) ?? Date()
        
        let predicate = #Predicate<ActivityLog> { log in
            log.injuryProfile?.id == profileID && log.date >= cutoffDate
        }
        
        let descriptor = FetchDescriptor<ActivityLog>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        
        return try context.fetch(descriptor)
    }
}
