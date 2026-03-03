import Foundation
import SwiftData

@Model
final class RecoveryRoadmap {
    var id: UUID
    var createdAt: Date
    var estimatedWeeks: Int
    var aiReasoning: String?
    
    var injuryProfile: InjuryProfile?
    
    @Relationship(deleteRule: .cascade)
    var phases: [RecoveryPhase] = []
    
    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        estimatedWeeks: Int = 0
    ) {
        self.id = id
        self.createdAt = createdAt
        self.estimatedWeeks = estimatedWeeks
    }
}

@Model
final class RecoveryPhase {
    var id: UUID
    var title: String
    var phaseDescription: String
    var order: Int
    
    var roadmap: RecoveryRoadmap?
    
    @Relationship(deleteRule: .cascade)
    var dailyRoutines: [DailyRoutine] = []
    
    init(
        id: UUID = UUID(),
        title: String,
        phaseDescription: String,
        order: Int
    ) {
        self.id = id
        self.title = title
        self.phaseDescription = phaseDescription
        self.order = order
    }
}

@Model
final class DailyRoutine {
    var id: UUID
    var dayTitle: String // e.g., "Lunes", "Día 1"
    var order: Int
    
    var phase: RecoveryPhase?
    
    @Relationship(deleteRule: .cascade)
    var exercises: [Exercise] = []
    
    init(
        id: UUID = UUID(),
        dayTitle: String,
        order: Int
    ) {
        self.id = id
        self.dayTitle = dayTitle
        self.order = order
    }
}
