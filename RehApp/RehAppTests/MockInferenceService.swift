import Foundation
@testable import RehApp

/// Mock del servicio de inferencia para pruebas unitarias.
/// Permite simular comportamientos de la IA sin procesar texto real.
final class MockInferenceService: LocalInferenceServiceProtocol, @unchecked Sendable {
    
    // Propiedades para controlar la respuesta del Mock
    var mockRoadmapToReturn: RecoveryRoadmap?
    var mockPrehabRoutineToReturn: [Exercise] = []
    
    // Espías para verificar interacciones
    var generateRoadmapCalled = false
    var lastInjuryProfileReceived: InjuryProfile?
    var generatePrehabCalled = false
    var lastBodyPartReceived: String?
    
    @MainActor
    func generateRoadmap(for injury: InjuryProfile) async -> RecoveryRoadmap {
        generateRoadmapCalled = true
        lastInjuryProfileReceived = injury
        return mockRoadmapToReturn ?? RecoveryRoadmap(estimatedWeeks: 4)
    }
    
    @MainActor
    func generatePrehabRoutine(for bodyPart: String) async -> [Exercise] {
        generatePrehabCalled = true
        lastBodyPartReceived = bodyPart
        return mockPrehabRoutineToReturn
    }
}
