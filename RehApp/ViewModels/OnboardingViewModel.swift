import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class OnboardingViewModel {
    var bodyPart: String = ""
    var painLevel: Int = 5
    var sport: String = ""
    var symptomsDescription: String = ""
    var medicalReportText: String? = nil // New property to hold medical report text for editing
    var selectedReportURL: URL?
    var isProcessing: Bool = false
    var recognizedText: String = ""
    var extractedSymptoms: [String] = []
    
    var daysPerWeek: Int = 3
    var exercisesPerDay: Int = 2
    var targetDuration: Int = 15
    
    private let healthService: HealthKitServiceProtocol
    private let inferenceService: LocalInferenceServiceProtocol
    private let scannerService: DocumentScannerServiceProtocol
    private let symptomService: SymptomAnalyzerServiceProtocol
    private let repository: RecoveryRepositoryProtocol
    
    var initialProfile: InjuryProfile?
    
    init(
        initialProfile: InjuryProfile? = nil,
        healthService: HealthKitServiceProtocol = HealthKitService(),
        inferenceService: LocalInferenceServiceProtocol = LocalInferenceService(),
        scannerService: DocumentScannerServiceProtocol = DocumentScannerService(),
        symptomService: SymptomAnalyzerServiceProtocol = SymptomAnalyzerService(),
        repository: RecoveryRepositoryProtocol
    ) {
        self.initialProfile = initialProfile
        self.healthService = healthService
        self.inferenceService = inferenceService
        self.scannerService = scannerService
        self.symptomService = symptomService
        self.repository = repository
        
        if let profile = initialProfile {
            self.bodyPart = profile.bodyPart
            self.painLevel = profile.painLevel
            self.sport = profile.sport
            self.symptomsDescription = profile.symptomsDescription
            self.medicalReportText = profile.medicalReportText
            self.daysPerWeek = profile.daysPerWeek
            self.exercisesPerDay = profile.exercisesPerDay
            self.targetDuration = profile.targetDuration
        }
    }
    
    func requestHealthPermissions() async -> Bool {
        do {
            return try await healthService.requestPermissions()
        } catch {
            return false
        }
    }
    
    @MainActor
    func saveProfile(context: ModelContext) async { // Renamed from createProfile
        isProcessing = true
        
        // Simulate deep analysis delay for AI feel
        try? await Task.sleep(for: .seconds(2))
        
        defer { isProcessing = false }
        
        // 1. Process PDF if exists (only for new reports or if changed)
        if let url = selectedReportURL {
            recognizedText = (try? await scannerService.scanPDF(url: url)) ?? ""
        }
        
        // 2. Extract Symptoms from both description and recognized text
        let combinedText = symptomsDescription + " " + (medicalReportText ?? "") + " " + recognizedText
        extractedSymptoms = await symptomService.extractSymptoms(from: combinedText)
        
        let profile: InjuryProfile
        if let existingProfile = initialProfile {
            // Update existing profile
            existingProfile.bodyPart = bodyPart
            existingProfile.painLevel = painLevel
            existingProfile.sport = sport
            existingProfile.symptomsDescription = symptomsDescription
            existingProfile.medicalReportText = medicalReportText
            existingProfile.daysPerWeek = daysPerWeek
            existingProfile.exercisesPerDay = exercisesPerDay
            existingProfile.targetDuration = targetDuration
            profile = existingProfile
        } else {
            // Create new profile
            profile = InjuryProfile(
                bodyPart: bodyPart,
                painLevel: painLevel,
                sport: sport,
                symptomsDescription: symptomsDescription,
                medicalReportText: medicalReportText,
                daysPerWeek: daysPerWeek,
                exercisesPerDay: exercisesPerDay,
                targetDuration: targetDuration
            )
            try? repository.saveInjuryProfile(profile)
            setupInitialMilestones(context: context)
        }
        
        if profile.roadmaps.isEmpty || initialProfile != nil {
            let newRoadmap = await inferenceService.generateRoadmap(for: profile)
            profile.roadmaps.append(newRoadmap)
            try? repository.saveRecoveryRoadmap(newRoadmap)
        }
    }
    
    func handleReportSelection(url: URL) {
        selectedReportURL = url
    }
    
    private func setupInitialMilestones(context: ModelContext) {
        let milestones = [
            Milestone(title: NSLocalizedString("MILESTONE_FIRST_STEP_TITLE", comment: ""), milestoneDescription: NSLocalizedString("MILESTONE_FIRST_STEP_DESC", comment: ""), requiredScore: 10, iconName: "figure.walk"),
            Milestone(title: NSLocalizedString("MILESTONE_CONSTANCY_TITLE", comment: ""), milestoneDescription: NSLocalizedString("MILESTONE_CONSTANCY_DESC", comment: ""), requiredScore: 100, iconName: "bolt.fill"),
            Milestone(title: NSLocalizedString("MILESTONE_TITAN_TITLE", comment: ""), milestoneDescription: NSLocalizedString("MILESTONE_TITAN_DESC", comment: ""), requiredScore: 500, iconName: "trophy.fill")
        ]
        milestones.forEach { context.insert($0) }
    }
}
