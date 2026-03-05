import Foundation
import SwiftData
import Observation
import AVFoundation

/// Estados posibles de una sesión de entrenamiento activa.
enum SessionState: Sendable {
    case notStarted // No iniciada
    case warmingUp // Calentamiento
    case exercising // Realizando ejercicio
    case resting // Descanso entre series
    case coolingDown // Enfriamiento/Estiramiento final
    case completed // Sesión terminada
    case paused // Pausada por el usuario
}

/// Bloques lógicos que componen la línea de tiempo de una sesión.
enum SessionBlock: Identifiable, Hashable {
    var id: Self { self }
    case warmUp(duration: TimeInterval)
    case exercise(Exercise)
    case rest(duration: TimeInterval)
    case coolDown(duration: TimeInterval)
}

/// ViewModel que controla la lógica de la sesión de ejercicios en tiempo real.
/// Maneja el cronómetro, la voz de guía, la gamificación y la integración con Salud.
@MainActor
@Observable
final class ExercisePlayerViewModel {
    let sessionBlocks: [SessionBlock] // Lista secuencial de lo que el usuario va a hacer
    var currentBlockIndex: Int = 0 // Índice del bloque actual
    var sessionState: SessionState = .notStarted
    
    // Propiedades calculadas para facilitar el acceso desde la Vista
    var currentBlock: SessionBlock { sessionBlocks[currentBlockIndex] }
    
    var currentExercise: Exercise {
        guard case .exercise(let exercise) = currentBlock else {
            fatalError("No se puede acceder a currentExercise fuera de un bloque de ejercicio.")
        }
        return exercise
    }
    
    var isTimerRunning: Bool { timerService.isRunning }
    var elapsedTime: TimeInterval { timerService.elapsedTime }
    
    var currentRep: Int = 0 // Repetición actual (estimada por tiempo)
    var currentSet: Int = 1 // Serie actual
    var showSummary: Bool = false // Controla si se muestra el resumen final
    
    private let profile: InjuryProfile
    private let healthService: HealthKitServiceProtocol
    private let gamificationEngine: GamificationEngineServiceProtocol
    private let repository: RecoveryRepositoryProtocol
    private let audioFeedbackService: AudioFeedbackServiceProtocol
    private let timerService: SessionTimerServiceProtocol
    
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
    
    /// Inicia la sesión desde el primer bloque no completado.
    func startSession() {
        audioFeedbackService.playFeedback(for: .sessionStarted)
        
        if let firstBlockIndex = sessionBlocks.firstIndex(where: { block in
            if case .exercise(let exercise) = block { return !exercise.isCompleted }
            return true
        }) {
            currentBlockIndex = firstBlockIndex
            startCurrentBlock()
        } else {
            finishSession()
        }
    } 
    
    /// Ejecuta la lógica del bloque actual (Voz + Cronómetro).
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
            if currentSet > exercise.sets {
                Task { await moveToNextBlock() }
                return
            }
            sessionState = .exercising
            currentRep = 0
            audioFeedbackService.playFeedback(for: .exerciseStarted(exerciseName: exercise.name))
            startExerciseBlock()
        }
    }
    
    /// Maneja bloques que tienen una duración fija (calentamiento, descanso).
    private func startTimedBlock(duration: TimeInterval) {
        timerService.startTimer(duration: duration) { [weak self] elapsedTime in
            guard let self = self else { return }
            let remaining = duration - elapsedTime
            // Cuenta atrás por voz en los últimos 3 segundos
            if remaining <= 3 && remaining > 0 {
                self.audioFeedbackService.playFeedback(for: .countdown(Int(remaining)))
            }
        } onComplete: { [weak self] in
            guard let self = self else { return }
            if self.sessionState == .resting {
                self.startCurrentBlock() // Reiniciamos el bloque de ejercicio
            } else {
                Task { await self.moveToNextBlock() }
            }
        }
    }

    /// Maneja bloques de ejercicio activo.
    private func startExerciseBlock() {
        timerService.startTimer(duration: nil) { [weak self] elapsedTime in
            guard let self = self else { return }
            guard case .exercise(let exercise) = self.currentBlock else { return }
            
            // Estimamos las repeticiones basadas en el tiempo para dar feedback de ritmo
            if let estimatedDuration = exercise.estimatedDurationPerRep, estimatedDuration > 0 {
                let potentialReps = Int(elapsedTime / estimatedDuration)
                if potentialReps > self.currentRep && potentialReps <= exercise.reps {
                    self.currentRep = potentialReps
                    // Consejos de ritmo dinámicos
                    if self.currentRep == exercise.reps / 3 {
                        self.audioFeedbackService.playFeedback(for: .pacingGuidance(message: "Mantén un ritmo constante."))
                    }
                }
            }
            
            // Consejos técnicos de postura a mitad del ejercicio
            if self.currentRep == exercise.reps / 2 && Int(elapsedTime) % 10 == 0 {
                 self.audioFeedbackService.playFeedback(for: .formTip(message: "Asegúrate de mantener la postura correcta."))
            }
        } onComplete: {}
    }
    
    /// Finaliza la serie actual, otorga puntos y decide si pasar al siguiente ejercicio o descansar.
    @MainActor
    func completeCurrentExerciseSet() async {
        guard case .exercise(let exercise) = currentBlock else { return }
        
        timerService.stopTimer()
        audioFeedbackService.playFeedback(for: .exerciseCompleted)
        
        do {
            // Gamificación: Procesamos la recompensa
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
            print("Error al completar ejercicio: \(error)")
        }
    }
    
    @MainActor
    private func moveToNextBlock() async {
        if currentBlockIndex < sessionBlocks.count - 1 {
            currentBlockIndex += 1
            startCurrentBlock()
        } else {
            await finishSession()
        }
    }
    
    /// Finaliza la sesión global, guarda en Salud y muestra el resumen.
    private func finishSession() async {
        // Cálculo estipulado de calorías (estimación simple para demo)
        let totalReps = sessionBlocks.reduce(0) { total, block in
            if case .exercise(let exercise) = block { return total + (exercise.reps * exercise.sets) }
            return total
        }
        let estimatedCalories = Double(totalReps) * 0.5
        
        // Guardar entrenamiento en HealthKit
        try? await healthService.saveWorkout(duration: elapsedTime, calories: estimatedCalories)
        
        sessionState = .completed
        showSummary = true
        audioFeedbackService.playFeedback(for: .sessionCompleted)
    }
    
    func pauseSession() {
        guard sessionState != .paused && sessionState != .completed else { return }
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
}
