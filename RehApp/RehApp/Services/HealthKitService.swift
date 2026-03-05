import Foundation
import HealthKit

/// Protocolo que define la interfaz para sincronizar con Apple Health (Salud).
protocol HealthKitServiceProtocol: Sendable {
    func requestPermissions() async throws -> Bool
    func saveWorkout(duration: TimeInterval, calories: Double) async throws
    func isAuthorized() -> Bool
}

/// Servicio encargado de la integración con Apple Health.
/// Permite que la actividad de rehabilitación compute para los anillos de actividad del Apple Watch.
final class HealthKitService: HealthKitServiceProtocol {
    private let healthStore = HKHealthStore()
    
    /// Solicita permisos al usuario para escribir datos de entrenamiento y energía.
    func requestPermissions() async throws -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            return false
        }
        
        let typesToShare: Set = [
            HKObjectType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        try await healthStore.requestAuthorization(toShare: typesToShare, read: [])
        return true
    }
    
    /// Comprueba si el usuario ya ha dado permisos.
    func isAuthorized() -> Bool {
        let status = healthStore.authorizationStatus(for: HKObjectType.workoutType())
        return status == .sharingAuthorized
    }
    
    /// Registra una sesión de rehabilitación como un entrenamiento oficial.
    /// Se clasifica como "Functional Strength Training".
    func saveWorkout(duration: TimeInterval, calories: Double) async throws {
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .functionalStrengthTraining
        workoutConfiguration.locationType = .indoor
        
        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: workoutConfiguration, device: .local())
        
        // Iniciamos la recolección de datos
        try await builder.beginCollection(at: Date().addingTimeInterval(-duration))
        
        // Registramos las calorías quemadas
        let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let calorieQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: calories)
        let calorieSample = HKQuantitySample(type: calorieType, quantity: calorieQuantity, start: Date().addingTimeInterval(-duration), end: Date())
        
        try await builder.addSamples([calorieSample])
        try await builder.endCollection(at: Date())
        
        // Finalizamos el entrenamiento en Salud
        _ = try await builder.finishWorkout()
    }
}
