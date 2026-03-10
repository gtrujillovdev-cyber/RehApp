import Foundation
import SwiftData

/// Modelo que registra la actividad diaria de rehabilitación del usuario.
/// Se utiliza para alimentar los gráficos de progreso y validar rachas.
@Model
final class ActivityLog {
    @Attribute(.unique) var id: UUID
    var date: Date          // Fecha en que se registró la actividad
    var scoreEarned: Int    // Puntos obtenidos en la sesión
    var durationMinutes: Int // Duración real de la sesión
    
    /// Relación con el perfil de lesión al que pertenece esta actividad.
    var injuryProfile: InjuryProfile?
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        scoreEarned: Int = 0,
        durationMinutes: Int = 0
    ) {
        self.id = id
        self.date = date
        self.scoreEarned = scoreEarned
        self.durationMinutes = durationMinutes
    }
}
