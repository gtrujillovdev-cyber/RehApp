import XCTest
import SwiftData
@testable import RehApp

final class GamificationEngineServiceTests: XCTestCase {
    var service: GamificationEngineService!
    var container: ModelContainer!
    
    @MainActor
    override func setUpWithError() throws {
        let schema = Schema([
            InjuryProfile.self,
            RecoveryRoadmap.self,
            RecoveryPhase.self,
            Exercise.self,
            DailyRoutine.self,
            Milestone.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        service = GamificationEngineService()
    }

    @MainActor
    func testProcessExerciseCompletion_UnlocksMilestones() async throws {
        // 1. Setup Data
        let context = container.mainContext
        let profile = InjuryProfile(bodyPart: "Rodilla", painLevel: 5, sport: "Ciclismo")
        let exercise = Exercise(name: "Sentadillas", reps: 10, sets: 3, pointsReward: 20)
        let milestone = Milestone(title: "First Step", milestoneDescription: "Test", requiredScore: 15, iconName: "star")
        
        context.insert(profile)
        context.insert(milestone)
        
        // 2. Execute
        let newlyUnlocked = try await service.processExerciseCompletion(exercise: exercise, profile: profile, context: context)
        
        // 3. Verify
        XCTAssertTrue(exercise.isCompleted)
        XCTAssertEqual(profile.recoveryScore, 20)
        XCTAssertEqual(profile.currentStreak, 1)
        XCTAssertEqual(newlyUnlocked.count, 1)
        XCTAssertEqual(newlyUnlocked.first?.title, "First Step")
        XCTAssertTrue(milestone.isUnlocked)
    }
}
