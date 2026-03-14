import Foundation
import SwiftData
import Observation

/// ViewModel para la pantalla principal (Dashboard).
/// Gestiona la lista de perfiles de lesión y la selección del plan activo.
@MainActor
@Observable
final class DashboardViewModel {
    var allProfiles: [InjuryProfile] = []
    var selectedProfile: InjuryProfile?
    var currentRoadmap: RecoveryRoadmap?
    var prehabRoutine: [Exercise] = []
    /// Mensaje de error para mostrar al usuario si una operación falla.
    /// La vista observa esta propiedad y presenta un .alert cuando no es nil.
    var errorMessage: String?
    var activityLogs: [ActivityLog] = []

    let repository: RecoveryRepositoryProtocol
    private let inferenceService: LocalInferenceServiceProtocol
    /// Handle de la Task de prehab activa. Guardarlo permite cancelarla si el usuario
    /// cambia de perfil antes de que termine, evitando que una respuesta tardía
    /// sobreescriba el resultado correcto del perfil nuevo.
    private var prehabTask: Task<Void, Never>?
    
    init(repository: RecoveryRepositoryProtocol, inferenceService: LocalInferenceServiceProtocol? = nil) {
        self.repository = repository
        self.inferenceService = inferenceService ?? LocalInferenceService()
        fetchLatestData()
    }
    
    /// Carga los datos más recientes desde el repositorio (SwiftData).
    func fetchLatestData() {
        do {
            allProfiles = try repository.fetchInjuryProfiles()
        } catch {
            // Escribimos en errorMessage en lugar de silenciar con try?
            // La vista puede observar esta propiedad y mostrar un .alert al usuario.
            errorMessage = "No se pudieron cargar los perfiles: \(error.localizedDescription)"
            allProfiles = []
        }

        if selectedProfile == nil {
            selectedProfile = allProfiles.first
        }

        currentRoadmap = selectedProfile?.roadmaps.last
        fetchActivityHistory()
        loadPrehab()
    }
    
    /// Carga el historial de actividad de los últimos 7 días.
    func fetchActivityHistory() {
        guard let profileID = selectedProfile?.id else { return }
        do {
            activityLogs = try repository.fetchActivityLogs(for: profileID, daysLimit: 7)
        } catch {
            print("Failed to fetch activity logs: \(error)")
        }
    }
    
    /// Carga una rutina de pre-habilitación (preventiva) usando el motor de IA.
    func loadPrehab() {
        // Cancelamos cualquier carga anterior antes de lanzar la nueva.
        // Sin esto, si el usuario cambia de perfil mientras se está cargando el prehab,
        // dos Tasks compiten: la más lenta sobreescribiría el resultado de la más rápida.
        prehabTask?.cancel()

        guard let bodyPart = selectedProfile?.bodyPart else { return }

        prehabTask = Task {
            let routine = await inferenceService.generatePrehabRoutine(for: bodyPart)
            // Comprobamos cancelación antes de escribir: si el perfil cambió
            // mientras esperábamos la respuesta, descartamos el resultado.
            guard !Task.isCancelled else { return }
            // La asignación directa funciona porque DashboardViewModel es @MainActor;
            // no hace falta await MainActor.run { } redundante.
            prehabRoutine = routine
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
        do {
            try repository.saveInjuryProfile(profile)
            selectedProfile = profile
            currentRoadmap = profile.roadmaps.last
            fetchLatestData()
        } catch {
            errorMessage = "No se pudo guardar el perfil: \(error.localizedDescription)"
        }
    }

    /// Elimina un perfil y sus datos asociados.
    func deleteInjuryProfile(_ profile: InjuryProfile) {
        do {
            try repository.deleteInjuryProfile(profile)
            if selectedProfile?.id == profile.id {
                selectedProfile = allProfiles.first(where: { $0.id != profile.id })
            }
            fetchLatestData()
        } catch {
            errorMessage = "No se pudo eliminar el perfil: \(error.localizedDescription)"
        }
    }
    
    /// Estadísticas rápidas para las tarjetas del Dashboard.
    var stats: (score: Int, streak: Int) {
        (selectedProfile?.recoveryScore ?? 0, selectedProfile?.currentStreak ?? 0)
    }
}
