import Foundation
import HealthKit

protocol HealthKitServiceProtocol: Sendable {
    func requestPermissions() async throws -> Bool
    func saveWorkout(duration: TimeInterval, calories: Double) async throws
    func isAuthorized() -> Bool
}

final class HealthKitService: HealthKitServiceProtocol {
    private let healthStore = HKHealthStore()
    
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
    
    func isAuthorized() -> Bool {
        let status = healthStore.authorizationStatus(for: HKObjectType.workoutType())
        return status == .sharingAuthorized
    }
    
    func saveWorkout(duration: TimeInterval, calories: Double) async throws {
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .functionalStrengthTraining
        workoutConfiguration.locationType = .indoor
        
        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: workoutConfiguration, device: .local())
        
        try await builder.beginCollection(at: Date().addingTimeInterval(-duration))
        
        let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let calorieQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: calories)
        let calorieSample = HKQuantitySample(type: calorieType, quantity: calorieQuantity, start: Date().addingTimeInterval(-duration), end: Date())
        
        try await builder.addSamples([calorieSample])
        try await builder.endCollection(at: Date())
        
        _ = try await builder.finishWorkout()
    }
}
