import Foundation
import SwiftData

@Model
final class InjuryProfile: Identifiable {
    var id: UUID
    var bodyPart: String
    var painLevel: Int // 1-10
    var sport: String
    var symptomsDescription: String
    var medicalReportText: String?
    var injuryDate: Date
    var recoveryScore: Int
    var currentStreak: Int
    
    var daysPerWeek: Int = 3
    var exercisesPerDay: Int = 2
    var targetDuration: Int = 15 // minutes
    
    @Relationship(deleteRule: .cascade, inverse: \RecoveryRoadmap.injuryProfile)
    var roadmaps: [RecoveryRoadmap] = []
    
    init(
        id: UUID = UUID(),
        bodyPart: String,
        painLevel: Int,
        sport: String,
        symptomsDescription: String,
        medicalReportText: String? = nil,
        injuryDate: Date = Date(),
        recoveryScore: Int = 0,
        currentStreak: Int = 0,
        daysPerWeek: Int = 3,
        exercisesPerDay: Int = 2,
        targetDuration: Int = 15
    ) {
        self.id = id
        self.bodyPart = bodyPart
        self.painLevel = painLevel
        self.sport = sport
        self.symptomsDescription = symptomsDescription
        self.medicalReportText = medicalReportText
        self.injuryDate = injuryDate
        self.recoveryScore = recoveryScore
        self.currentStreak = currentStreak
        self.daysPerWeek = daysPerWeek
        self.exercisesPerDay = exercisesPerDay
        self.targetDuration = targetDuration
    }
}
