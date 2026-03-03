import Foundation
import SwiftData

@Model
final class Milestone {
    var id: UUID
    var title: String
    var milestoneDescription: String
    var requiredScore: Int
    var iconName: String // SF Symbols
    var isUnlocked: Bool
    var unlockedAt: Date?
    
    init(
        id: UUID = UUID(),
        title: String,
        milestoneDescription: String,
        requiredScore: Int,
        iconName: String,
        isUnlocked: Bool = false,
        unlockedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.milestoneDescription = milestoneDescription
        self.requiredScore = requiredScore
        self.iconName = iconName
        self.isUnlocked = isUnlocked
        self.unlockedAt = unlockedAt
    }
}
