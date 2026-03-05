import Foundation
import SwiftData

/// Modelo que representa un logro o hito dentro de la recuperación.
/// Se utiliza para motivar al usuario mediante la gamificación.
@Model
final class Milestone {
    var id: UUID
    var title: String // Título del hito (ej. "Primer Paso")
    var milestoneDescription: String // Explicación de qué se ha logrado
    var requiredScore: Int // Puntuación necesaria para desbloquearlo
    var iconName: String // Nombre del icono de SF Symbols
    var isUnlocked: Bool // Estado de desbloqueo
    var unlockedAt: Date? // Fecha en la que se consiguió el hito
    
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
