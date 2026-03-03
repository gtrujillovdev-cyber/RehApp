import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class DashboardViewModel {
    var allProfiles: [InjuryProfile] = []
    var selectedProfile: InjuryProfile?
    var currentRoadmap: RecoveryRoadmap?
    var prehabRoutine: [Exercise] = []
    
    let repository: RecoveryRepositoryProtocol
    private let inferenceService: LocalInferenceServiceProtocol
    
    init(repository: RecoveryRepositoryProtocol, inferenceService: LocalInferenceServiceProtocol = LocalInferenceService()) {
        self.repository = repository
        self.inferenceService = inferenceService
        fetchLatestData()
    }
    
    func fetchLatestData() {
        allProfiles = (try? repository.fetchInjuryProfiles()) ?? []
        
        if selectedProfile == nil {
            selectedProfile = allProfiles.first
        }
        
        currentRoadmap = selectedProfile?.roadmaps.last
        loadPrehab()
    }
    
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
    
    func selectProfile(_ profile: InjuryProfile) {
        selectedProfile = profile
        currentRoadmap = profile.roadmaps.last
        loadPrehab()
    }
    
    func addInjuryProfile(_ profile: InjuryProfile) {
        try? repository.saveInjuryProfile(profile)
        selectedProfile = profile
        currentRoadmap = profile.roadmaps.last
        fetchLatestData()
    }
    
    func deleteInjuryProfile(_ profile: InjuryProfile) {
        try? repository.deleteInjuryProfile(profile)
        if selectedProfile?.id == profile.id {
            selectedProfile = allProfiles.first(where: { $0.id != profile.id })
        }
        fetchLatestData()
    }
    
    // For editing, SwiftData automatically tracks changes to @Model objects,
    // so no explicit 'edit' method is strictly necessary in the ViewModel for simple property changes.
    // Changes to properties of 'selectedProfile' will persist when the context saves.
    
    var stats: (score: Int, streak: Int) {
        (selectedProfile?.recoveryScore ?? 0, selectedProfile?.currentStreak ?? 0)
    }
}
