import Foundation
import SwiftData

/// Modelo que representa la definición de un logro dentro de la gamificación.
///
/// DISEÑO DE LA RELACIÓN CON InjuryProfile (muchos a muchos):
/// Un hito puede ser desbloqueado por varios perfiles, y un perfil puede
/// desbloquear varios hitos. La relación se declara en InjuryProfile
/// (lado propietario) con `inverse: \Milestone.unlockedByProfiles`.
/// SwiftData crea automáticamente una tabla intermedia en SQLite para gestionar
/// esta asociación sin que tengamos que definirla explícitamente.
///
/// Nota de diseño sobre `isUnlocked` y `unlockedAt`:
/// Estos campos son actualmente "estado global" del hito, no por perfil.
/// La solución ideal sería un modelo intermedio `MilestoneUnlock` que almacene
/// (perfil, hito, fecha) — pero eso requiere una migración de esquema.
/// Por ahora, usarlos en conjunto con `unlockedByProfiles` es la solución
/// práctica: `isUnlocked` se puede derivar de `!unlockedByProfiles.isEmpty`.
@Model
final class Milestone {
    var id: UUID
    var title: String               // Título del hito (ej. "Primer Paso")
    var milestoneDescription: String // Explicación de qué se ha logrado
    var requiredScore: Int          // Puntuación necesaria para desbloquearlo
    var iconName: String            // Nombre del icono de SF Symbols
    var isUnlocked: Bool            // Estado global de desbloqueo
    var unlockedAt: Date?           // Fecha en la que se consiguió por primera vez

    /// Lado inverso de la relación muchos-a-muchos con InjuryProfile.
    /// No lleva `@Relationship` propio: la relación está gestionada desde
    /// `InjuryProfile.unlockedMilestones` con deleteRule y inverse explícitos.
    var unlockedByProfiles: [InjuryProfile] = []

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
