import Foundation
import SwiftData

@MainActor
protocol RecoveryRepositoryProtocol: Sendable {
    func saveInjuryProfile(_ profile: InjuryProfile) throws
    func deleteInjuryProfile(_ profile: InjuryProfile) throws
    func fetchInjuryProfiles() throws -> [InjuryProfile]
    func saveRecoveryRoadmap(_ roadmap: RecoveryRoadmap) throws
}

@MainActor
final class RecoveryRepository: RecoveryRepositoryProtocol {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    @MainActor func saveInjuryProfile(_ profile: InjuryProfile) throws {
        context.insert(profile)
        do {
            try context.save()
        } catch {
            print("Failed to save injury profile: \(error)")
            throw error
        }
    }
    
    @MainActor func deleteInjuryProfile(_ profile: InjuryProfile) throws {
        context.delete(profile)
        do {
            try context.save()
        } catch {
            print("Failed to delete injury profile: \(error)")
            throw error
        }
    }
    
    @MainActor func fetchInjuryProfiles() throws -> [InjuryProfile] {
        let descriptor = FetchDescriptor<InjuryProfile>()
        do {
            return try context.fetch(descriptor)
        } catch {
            print("Failed to fetch injury profiles: \(error)")
            throw error
        }
    }
    
    @MainActor func saveRecoveryRoadmap(_ roadmap: RecoveryRoadmap) throws {
        context.insert(roadmap)
        do {
            try context.save()
        } catch {
            print("Failed to save recovery roadmap: \(error)")
            throw error
        }
    }
}
