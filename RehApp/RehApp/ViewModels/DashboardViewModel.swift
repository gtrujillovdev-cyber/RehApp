import Foundation
import SwiftData
import Observation

/// ViewModel para la pantalla principal (Dashboard).
/// Gestiona la lista de perfiles de lesión y la selección del plan activo.
@MainActor
@Observable
final class DashboardViewModel {
    var allProfiles: [InjuryProfile] = [] // Todos los perfiles guardados en SwiftData
    var selectedProfile: InjuryProfile? // El perfil que el usuario está viendo actualmente
    var currentRoadmap: RecoveryRoadmap? // El plan de recuperación activo para el perfil seleccionado
    var prehabRoutine: [Exercise] = [] // Rutina preventiva generada dinámicamente
    
    let repository: RecoveryRepositoryProtocol
    private let inferenceService: LocalInferenceServiceProtocol
    
    init(repository: RecoveryRepositoryProtocol, inferenceService: LocalInferenceServiceProtocol = LocalInferenceService()) {
        self.repository = repository
        self.inferenceService = inferenceService
        fetchLatestData()
    }
    
    /// Carga los datos más recientes desde el repositorio (SwiftData).
    func fetchLatestData() {
        allProfiles = (try? repository.fetchInjuryProfiles()) ?? []
        
        // Si no hay perfil seleccionado, cogemos el primero por defecto
        if selectedProfile == nil {
            selectedProfile = allProfiles.first
        }
        
        currentRoadmap = selectedProfile?.roadmaps.last
        loadPrehab() // Cargamos la rutina preventiva para la zona afectada
    }
    
    /// Carga una rutina de pre-habilitación (preventiva) usando el motor de IA.
    func loadPrehab() {
        Task {
            if let bodyPart = selectedProfile?.bodyPart {
                let routine = await inferenceService.generatePrehabRoutine(for: bodyPart)
                await MainActor.run {
                    self.prehabRoutine = routine
                }
            }
        }
    }
    
    /// Cambia el perfil activo y actualiza la interfaz.
    func selectProfile(_ profile: InjuryProfile) {
        selectedProfile = profile
        currentRoadmap = profile.roadmaps.last
        loadPrehab()
    }
    
    /// Añade un nuevo perfil de lesión y lo establece como activo.
    func addInjuryProfile(_ profile: InjuryProfile) {
        try? repository.saveInjuryProfile(profile)
        selectedProfile = profile
        currentRoadmap = profile.roadmaps.last
        fetchLatestData()
    }
    
    /// Elimina un perfil y sus datos asociados.
    func deleteInjuryProfile(_ profile: InjuryProfile) {
        try? repository.deleteInjuryProfile(profile)
        if selectedProfile?.id == profile.id {
            selectedProfile = allProfiles.first(where: { $0.id != profile.id })
        }
        fetchLatestData()
    }
    
    /// Estadísticas rápidas para las tarjetas del Dashboard.
    var stats: (score: Int, streak: Int) {
        (selectedProfile?.recoveryScore ?? 0, selectedProfile?.currentStreak ?? 0)
    }
}
