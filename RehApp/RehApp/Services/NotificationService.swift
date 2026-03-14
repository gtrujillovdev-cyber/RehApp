import Foundation
import UserNotifications

/// Protocolo para el servicio de notificaciones locales de gamificación y adherencia
protocol NotificationServiceProtocol: Sendable {
    func requestAuthorization() async throws -> Bool
    func scheduleDailyReminder(hour: Int, minute: Int) async throws
    func cancelAllReminders()
}

/// Servicio encargado de programar los recordatorios diarios tipo "No rompas tu racha".
final class NotificationService: NotificationServiceProtocol {
    
    func requestAuthorization() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        return try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }
    
    func scheduleDailyReminder(hour: Int, minute: Int) async throws {
        let center = UNUserNotificationCenter.current()
        
        // Primero solicitamos permiso por si el usuario nunca lo ha dado
        let granted = try await requestAuthorization()
        guard granted else { return }
        
        // Cancelar recordatorios previos para evitar duplicados
        cancelAllReminders()
        
        let content = UNMutableNotificationContent()
        content.title = "Hora de entrenar 🔥"
        content.body = "No rompas tu racha de recuperación física. Completa tu sesión clínica de hoy."
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_rehab_reminder", content: content, trigger: trigger)
        
        try await center.add(request)
    }
    
    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
