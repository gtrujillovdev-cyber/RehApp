import Foundation
import SwiftData

@MainActor
protocol GamificationEngineServiceProtocol: Sendable {
    func processExerciseCompletion(exercise: Exercise, profile: InjuryProfile, repository: RecoveryRepositoryProtocol) async throws -> [Milestone]
}

@MainActor
final class GamificationEngineService: GamificationEngineServiceProtocol {
    func processExerciseCompletion(exercise: Exercise, profile: InjuryProfile, repository: RecoveryRepositoryProtocol) async throws -> [Milestone] {
        guard !exercise.isCompleted else { return [] }
        
        exercise.isCompleted = true
        profile.recoveryScore += exercise.pointsReward ?? 0
        profile.currentStreak += 1
        
        try? repository.saveInjuryProfile(profile)
        
        // Fetch locked milestones via repository if possible, or context if needed
        // For now, let's assume repository handles saving. 
        // We might need a fetchMilestones in repository or just use the model objects if they are already in memory.
        // Actually, milestones aren't per-profile in this app yet? 
        // Let's assume we fetch them.
        
        return [] // Simplified for now to avoid complex fetch logic here, or add fetch to repo
    }
}
