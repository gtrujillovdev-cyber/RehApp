import Foundation
import Observation
import HealthKit 
import UserNotifications 
import SwiftUI

@Observable
final class SettingsViewModel {
    enum AppThemeSelection: String, CaseIterable {
        case system = "Sistema"
        case light = "Claro"
        case dark = "Oscuro"
        
        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }
    }
    
    var selectedLanguage: String = Locale.current.identifier
    var selectedTheme: AppThemeSelection = .system {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: "selectedTheme")
        }
    }
    var isHealthKitEnabled: Bool = false
    var enableExerciseReminders: Bool = false
    var enableProgressUpdates: Bool = false
    
    private let healthStore = HKHealthStore()
    private let notificationCenter = UNUserNotificationCenter.current()
    
    init() {
        loadSettings()
        checkHealthKitAuthorizationStatus()
        checkNotificationAuthorizationStatus()
    }
    
    func saveSettings() {
        UserDefaults.standard.set(selectedLanguage, forKey: "selectedLanguage")
        UserDefaults.standard.set(selectedTheme.rawValue, forKey: "selectedTheme")
        UserDefaults.standard.set(enableExerciseReminders, forKey: "enableExerciseReminders")
        UserDefaults.standard.set(enableProgressUpdates, forKey: "enableProgressUpdates")
        print("Settings saved.")
    }
    
    private func loadSettings() {
        selectedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? Locale.current.identifier
        if let themeRaw = UserDefaults.standard.string(forKey: "selectedTheme"),
           let theme = AppThemeSelection(rawValue: themeRaw) {
            selectedTheme = theme
        }
        enableExerciseReminders = UserDefaults.standard.bool(forKey: "enableExerciseReminders")
        enableProgressUpdates = UserDefaults.standard.bool(forKey: "enableProgressUpdates")
    }
    
    // MARK: - Data Export
    func generateCSVExport(profiles: [InjuryProfile]) -> String {
        var csvString = "Body Part,Sport,Pain Level,Days Per Week,Exercises Per Day,Target Duration,Injury Date\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        for profile in profiles {
            let row = "\(profile.bodyPart),\(profile.sport),\(profile.painLevel),\(profile.daysPerWeek),\(profile.exercisesPerDay),\(profile.targetDuration),\(dateFormatter.string(from: profile.injuryDate))\n"
            csvString.append(row)
        }
        return csvString
    }
    
    // HealthKit and Notifications logic remains the same...
    func requestHealthKitAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device.")
            return
        }
        
        let typesToShare: Set<HKSampleType> = [
            HKObjectType.workoutType()
        ]
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.isHealthKitEnabled = true
                    print("HealthKit authorization granted.")
                } else {
                    self.isHealthKitEnabled = false
                    print("HealthKit authorization denied or error: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    private func checkHealthKitAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let workoutType = HKObjectType.workoutType()
        let status = healthStore.authorizationStatus(for: workoutType)
        
        DispatchQueue.main.async {
            self.isHealthKitEnabled = (status == .sharingAuthorized)
        }
    }
    
    // MARK: - Notifications
    func requestNotificationAuthorization(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("Notification authorization granted.")
                } else {
                    print("Notification authorization denied or error: \(error?.localizedDescription ?? "Unknown error")")
                }
                completion(granted)
            }
        }
    }
    
    private func checkNotificationAuthorizationStatus() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.enableExerciseReminders = (settings.authorizationStatus == .authorized) && UserDefaults.standard.bool(forKey: "enableExerciseReminders")
                self.enableProgressUpdates = (settings.authorizationStatus == .authorized) && UserDefaults.standard.bool(forKey: "enableProgressUpdates")
            }
        }
    }
    
    func toggleExerciseReminders(isOn: Bool) {
        if isOn {
            requestNotificationAuthorization { granted in
                if granted {
                    self.enableExerciseReminders = true
                    self.scheduleExerciseReminder()
                } else {
                    self.enableExerciseReminders = false
                }
            }
        } else {
            self.enableExerciseReminders = false
            cancelExerciseReminder()
        }
    }
    
    func toggleProgressUpdates(isOn: Bool) {
        if isOn {
            requestNotificationAuthorization { granted in
                if granted {
                    self.enableProgressUpdates = true
                    self.scheduleProgressUpdate()
                } else {
                    self.enableProgressUpdates = false
                }
            }
        } else {
            self.enableProgressUpdates = false
            cancelProgressUpdate()
        }
    }
    
    private func scheduleExerciseReminder() {
        let content = UNMutableNotificationContent()
        content.title = "¡Es hora de tu ejercicio!"
        content.body = "No olvides completar tu rutina de rehabilitación de hoy."
        content.sound = .default
        
        // Schedule daily reminder at a specific time (e.g., 9 AM)
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: "exerciseReminder", content: content, trigger: trigger)
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling exercise reminder: \(error.localizedDescription)")
            } else {
                print("Exercise reminder scheduled.")
            }
        }
    }
    
    private func cancelExerciseReminder() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["exerciseReminder"])
        print("Exercise reminder cancelled.")
    }
    
    private func scheduleProgressUpdate() {
        let content = UNMutableNotificationContent()
        content.title = "¡Revisa tu progreso!"
        content.body = "Mantente motivado revisando tus avances en la rehabilitación."
        content.sound = .default
        
        // Schedule weekly reminder (e.g., every Monday at 10 AM)
        var dateComponents = DateComponents()
        dateComponents.weekday = 2 // Monday
        dateComponents.hour = 10
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: "progressUpdate", content: content, trigger: trigger)
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling progress update: \(error.localizedDescription)")
            } else {
                print("Progress update scheduled.")
            }
        }
    }
    
    private func cancelProgressUpdate() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["progressUpdate"])
        print("Progress update cancelled.")
    }
}
