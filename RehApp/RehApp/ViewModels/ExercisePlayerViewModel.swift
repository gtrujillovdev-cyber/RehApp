import Foundation
import SwiftData
import Observation
import AVFoundation // Import AVFoundation for audio feedback

enum SessionState: Sendable {
    case notStarted
    case warmingUp
    case exercising
    case resting
    case coolingDown
    case completed
    case paused
}

enum SessionBlock: Identifiable, Hashable {
    var id: Self { self }
    case warmUp(duration: TimeInterval)
    case exercise(Exercise)
    case rest(duration: TimeInterval)
    case coolDown(duration: TimeInterval)
}

@MainActor
@Observable
final class ExercisePlayerViewModel {
    let sessionBlocks: [SessionBlock]
    var currentBlockIndex: Int = 0
    var sessionState: SessionState = .notStarted
    
    var currentBlock: SessionBlock {
        sessionBlocks[currentBlockIndex]
    }
    
    var currentExercise: Exercise {
        guard case .exercise(let exercise) = currentBlock else {
            fatalError("Attempted to access currentExercise when currentBlock is not an exercise.")
        }
        return exercise
    }
    
    var isTimerRunning: Bool {
        timerService.isRunning
    }
    
    var elapsedTime: TimeInterval {
        timerService.elapsedTime
    }
    
    var currentRep: Int = 0
    var currentSet: Int = 1
    var showSummary: Bool = false
    
    private let profile: InjuryProfile
    private let healthService: HealthKitServiceProtocol
    private let gamificationEngine: GamificationEngineServiceProtocol
    private let repository: RecoveryRepositoryProtocol
    private let audioFeedbackService: AudioFeedbackServiceProtocol
    private let timerService: SessionTimerServiceProtocol
    
    // Default rest duration between sets
    private let restDurationBetweenSets: TimeInterval = 30
    
    init(
        sessionBlocks: [SessionBlock],
        profile: InjuryProfile,
        healthService: HealthKitServiceProtocol = HealthKitService(),
        gamificationEngine: (any GamificationEngineServiceProtocol)? = nil,
        repository: RecoveryRepositoryProtocol,
        audioFeedbackService: AudioFeedbackServiceProtocol = AudioFeedbackService(),
        timerService: (any SessionTimerServiceProtocol)? = nil
    ) {
        self.sessionBlocks = sessionBlocks
        self.profile = profile
        self.healthService = healthService
        self.gamificationEngine = gamificationEngine ?? GamificationEngineService()
        self.repository = repository
        self.audioFeedbackService = audioFeedbackService
        self.timerService = timerService ?? SessionTimerService()
    }
    
    func startSession() {
        audioFeedbackService.playFeedback(for: .sessionStarted)
        // Find the first non-completed block and start from there
        if let firstBlockIndex = sessionBlocks.firstIndex(where: { block in
            if case .exercise(let exercise) = block { return !exercise.isCompleted }
            return true
        }) {
            currentBlockIndex = firstBlockIndex
            startCurrentBlock()
        } else {
            sessionState = .completed
            showSummary = true
            audioFeedbackService.playFeedback(for: .sessionCompleted)
        }
    } 
    
    private func startCurrentBlock() {
        switch currentBlock {
        case .warmUp(let duration):
            sessionState = .warmingUp
            audioFeedbackService.playFeedback(for: .warmUpStarted)
            startTimedBlock(duration: duration)
        case .rest(let duration):
            sessionState = .resting
            audioFeedbackService.playFeedback(for: .restStarted)
            startTimedBlock(duration: duration)
        case .coolDown(let duration):
            sessionState = .coolingDown
            audioFeedbackService.playFeedback(for: .coolDownStarted)
            startTimedBlock(duration: duration)
        case .exercise(let exercise):
            if currentSet > exercise.sets { // All sets completed for this exercise
                Task { await moveToNextBlock() }
                return
            }
            sessionState = .exercising
            currentRep = 0
            audioFeedbackService.playFeedback(for: .exerciseStarted(exerciseName: exercise.name))
            startExerciseBlock()
        }
    }
    
    private func startTimedBlock(duration: TimeInterval) {
        timerService.startTimer(duration: duration) { [weak self] elapsedTime in
            guard let self = self else { return }
            let remaining = duration - elapsedTime
            if remaining <= 3 && remaining > 0 {
                self.audioFeedbackService.playFeedback(for: .countdown(Int(remaining)))
            }
        } onComplete: { [weak self] in
            guard let self = self else { return }
            if self.sessionState == .resting && self.currentBlockIndex >= 0 {
                self.startCurrentBlock() // Restart the current exercise block
            } else {
                Task { await self.moveToNextBlock() }
            }
        }
    }

    private func startExerciseBlock() {
        timerService.startTimer(duration: nil) { [weak self] elapsedTime in
            guard let self = self else { return }
            guard case .exercise(let exercise) = self.currentBlock else { return }
            
            if let estimatedDuration = exercise.estimatedDurationPerRep, estimatedDuration > 0 {
                let potentialReps = Int(elapsedTime / estimatedDuration)
                if potentialReps > self.currentRep && potentialReps <= exercise.reps {
                    self.currentRep = potentialReps
                    // Pacing guidance
                    if self.currentRep == exercise.reps / 3 {
                        self.audioFeedbackService.playFeedback(for: .pacingGuidance(message: "Mantén un ritmo constante."))
                    } else if self.currentRep == (exercise.reps * 2) / 3 {
                        self.audioFeedbackService.playFeedback(for: .pacingGuidance(message: "Estás haciendo un gran trabajo, no bajes el ritmo."))
                    }
                }
            } else {
                if Int(elapsedTime) % 3 == 0 && self.currentRep < exercise.reps {
                    self.currentRep += 1
                    if self.currentRep == exercise.reps / 3 {
                        self.audioFeedbackService.playFeedback(for: .pacingGuidance(message: "Sigue el movimiento con fluidez."))
                    }
                }
            }
            // Form tip
            if self.currentRep == exercise.reps / 2 && Int(elapsedTime) % 10 == 0 {
                 self.audioFeedbackService.playFeedback(for: .formTip(message: "Asegúrate de mantener la postura correcta."))
            }
        } onComplete: {}
    }
    
    @MainActor
    func completeCurrentExerciseSet() async {
        guard case .exercise(let exercise) = currentBlock else { return }
        
        timerService.stopTimer()
        audioFeedbackService.playFeedback(for: .exerciseCompleted)
        
        do {
            _ = try await gamificationEngine.processExerciseCompletion(exercise: exercise, profile: profile, repository: repository)
            
            if currentSet < exercise.sets {
                currentSet += 1
                sessionState = .resting
                audioFeedbackService.playFeedback(for: .restStarted)
                startTimedBlock(duration: restDurationBetweenSets)
            } else {
                currentSet = 1
                await moveToNextBlock()
            }
        } catch {
            print("Error completing exercise: \(error)")
        }
    }
    
    @MainActor
    private func moveToNextBlock() async {
        if currentBlockIndex < sessionBlocks.count - 1 {
            currentBlockIndex += 1
            startCurrentBlock()
        } else {
            let totalReps = sessionBlocks.reduce(0) { total, block in
                if case .exercise(let exercise) = block { return total + (exercise.reps * exercise.sets) }
                return total
            }
            let estimatedCalories = Double(totalReps) * 0.5
            try? await healthService.saveWorkout(duration: elapsedTime, calories: estimatedCalories)
            
            sessionState = .completed
            showSummary = true
            audioFeedbackService.playFeedback(for: .sessionCompleted)
        }
    }
    
    func pauseSession() {
        guard sessionState == .exercising || sessionState == .warmingUp || sessionState == .resting || sessionState == .coolingDown else { return }
        timerService.pauseTimer()
        sessionState = .paused
        audioFeedbackService.playFeedback(for: .sessionPaused)
    }
    
    func resumeSession() {
        guard sessionState == .paused else { return }
        timerService.resumeTimer()
        
        switch currentBlock {
        case .warmUp: sessionState = .warmingUp
        case .exercise: sessionState = .exercising
        case .rest: sessionState = .resting
        case .coolDown: sessionState = .coolingDown
        }
        audioFeedbackService.playFeedback(for: .sessionResumed)
    }
    
    func skipCurrentBlock() {
        timerService.stopTimer()
        currentSet = 1
        audioFeedbackService.playFeedback(for: .blockSkipped)
        Task { await moveToNextBlock() }
    }
    
    func repeatCurrentBlock() {
        timerService.stopTimer()
        currentSet = 1
        startCurrentBlock()
    }
    
    var currentTimedBlockDuration: TimeInterval? {
        switch currentBlock {
        case .warmUp(let duration): return duration
        case .rest(let duration): return duration
        case .coolDown(let duration): return duration
        case .exercise: return nil
        }
    }
}
