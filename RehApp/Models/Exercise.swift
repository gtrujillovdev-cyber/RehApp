import Foundation
import SwiftData

@Model
final class Exercise {
    var id: UUID
    var name: String
    var reps: Int
    var sets: Int
    var animationModelID: String
    var isCompleted: Bool
    var technicalDescription: String?
    var instructions: [String]?
    var pointsReward: Int?
    var estimatedDurationPerRep: TimeInterval? // New property
    
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
        estimatedDurationPerRep: TimeInterval? = nil // New property in init
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
