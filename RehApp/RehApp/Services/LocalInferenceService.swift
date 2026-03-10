import Foundation
import NaturalLanguage

/// Protocolo que define las capacidades del motor de inferencia local.
protocol LocalInferenceServiceProtocol: Sendable {
    @MainActor func generateRoadmap(for injury: InjuryProfile) async -> RecoveryRoadmap
    @MainActor func generatePrehabRoutine(for bodyPart: String) async -> [Exercise]
}

/// Servicio encargado de generar planes de recuperación personalizados mediante IA local.
/// No envía datos a la nube, procesa todo en el dispositivo para máxima privacidad.
final class LocalInferenceService: LocalInferenceServiceProtocol {
    
    private let libraryService: ExerciseLibraryServiceProtocol
    
    init(libraryService: ExerciseLibraryServiceProtocol = ExerciseLibraryService()) {
        self.libraryService = libraryService
    }
    
    /// Genera una hoja de ruta completa basada en el perfil de la lesión.
    @MainActor func generateRoadmap(for injury: InjuryProfile) async -> RecoveryRoadmap {
        // Ejecutamos la lógica de cálculo en un hilo de fondo (global actor o detached task)
        // para no bloquear la UI durante el procesamiento de texto y generación de cientos de objetos.
        return await Task.detached(priority: .userInitiated) {
            let reportText = injury.medicalReportText ?? ""
            let symptoms = injury.symptomsDescription
            let combinedText = "\(reportText) \(symptoms)".lowercased()
            
            // 1. Analizar el texto usando NLP para detectar gravedad
            let analysis = self.analyzeText(combinedText)
            let isAcute = analysis.containsAcuteKeywords || injury.painLevel > 7
            let isStructural = analysis.containsStructuralKeywords
            
            // 2. Estimar semanas totales de recuperación
            let estimatedWeeks = MedicalAnalysis.estimateWeeks(isStructural: isStructural, isAcute: isAcute, painLevel: injury.painLevel)
            
            // Los modelos SwiftData deben interactuar con el contexto en el MainActor
            // pero podemos calcular la estructura fuera.
            
            let weeksPerPhase = max(1, estimatedWeeks / 4)
            
            return await MainActor.run {
                let roadmap = RecoveryRoadmap(estimatedWeeks: estimatedWeeks)
                
                // 3. Generar el razonamiento de la IA
                let baseReasoning = String(format: NSLocalizedString("REASONING_BASE", comment: ""), injury.bodyPart, injury.sport, roadmap.estimatedWeeks)
                var detailedReasoning = ""
                
                if isStructural {
                    detailedReasoning = NSLocalizedString("REASONING_STRUCTURAL", comment: "")
                } else if isAcute {
                    detailedReasoning = String(format: NSLocalizedString("REASONING_ACUTE", comment: ""), injury.painLevel)
                } else {
                    detailedReasoning = NSLocalizedString("REASONING_FUNCTIONAL", comment: "")
                }
                
                roadmap.aiReasoning = "\(baseReasoning) \(detailedReasoning)"
                
                // 4. Crear las 4 Fases de Recuperación
                let phase1 = self.createPhase(order: 1, title: "Control y Protección", weeks: weeksPerPhase, startWeek: 1, factor: 0.5, injury: injury)
                let phase2 = self.createPhase(order: 2, title: "Movilidad y Activación", weeks: weeksPerPhase, startWeek: weeksPerPhase + 1, factor: 0.7, injury: injury)
                let phase3 = self.createPhase(order: 3, title: "Carga Progresiva", weeks: weeksPerPhase, startWeek: (2 * weeksPerPhase) + 1, factor: 0.9, injury: injury)
                let phase4 = self.createPhase(order: 4, title: "Retorno al Rendimiento", weeks: estimatedWeeks - (3 * weeksPerPhase), startWeek: (3 * weeksPerPhase) + 1, factor: 1.2, injury: injury)
                
                roadmap.phases = [phase1, phase2, phase3, phase4]
                return roadmap
            }
        }.value
    }

    private func createPhase(order: Int, title: String, weeks: Int, startWeek: Int, factor: Double, injury: InjuryProfile) -> RecoveryPhase {
        let endWeek = startWeek + weeks - 1
        let description = "Semanas \(startWeek)-\(endWeek). \(getPhaseBaseDescription(order))"
        let phase = RecoveryPhase(title: title, phaseDescription: description, order: order)
        phase.dailyRoutines = generateDynamicRoutines(for: injury, factor: factor, phase: order, weeksInPhase: weeks, startWeek: startWeek)
        return phase
    }

    private func getPhaseBaseDescription(_ order: Int) -> String {
        switch order {
        case 1: return "Reducción de inflamación y protección del tejido lesionado. Carga mínima."
        case 2: return "Recuperación del rango de movimiento y activación muscular neuromuscular."
        case 3: return "Fortalecimiento específico y adaptación a la carga mecánica."
        case 4: return "Preparación para el alta competitiva y gestos técnicos."
        default: return ""
        }
    }
    
    /// Genera rutinas diarias variadas para cada fase, ajustando la intensidad (factor).
    private func generateDynamicRoutines(for injury: InjuryProfile, factor: Double, phase: Int, weeksInPhase: Int, startWeek: Int) -> [DailyRoutine] {
        var routines: [DailyRoutine] = []
        let dayShortcuts = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]
        
        let preferredDays = injury.daysPerWeek
        let interval = max(1, 7 / preferredDays)
        
        // Obtenemos ejercicios del servicio bibliotecario
        let primaryPool = libraryService.getExercises(for: injury.bodyPart, type: "primary")
        let secondaryPool = libraryService.getExercises(for: injury.bodyPart, type: "secondary")
        
        for week in 0..<weeksInPhase {
            let actualWeek = startWeek + week
            
            for i in 0..<preferredDays {
                let dayIndex = (i * interval) % 7
                let dayTitle = "\(dayShortcuts[dayIndex]) (Semana \(actualWeek))"
                let routine = DailyRoutine(dayTitle: dayTitle, order: (week * preferredDays) + i + 1)
                
                var usedNames = Set<String>()
                
                for j in 0..<injury.exercisesPerDay {
                    let exercise: Exercise
                    
                    if j == 0 && phase >= 4 {
                        exercise = generateSportSpecificExercise(for: injury)
                    } else if j % 2 == 0 {
                        let available = primaryPool.filter { !usedNames.contains($0.name) }
                        let base = available.randomElement() ?? primaryPool.randomElement()!
                        exercise = scaleExercise(base, factor: factor)
                    } else {
                        let available = secondaryPool.filter { !usedNames.contains($0.name) }
                        let base = available.randomElement() ?? secondaryPool.randomElement()!
                        exercise = scaleExercise(base, factor: factor)
                    }
                    
                    usedNames.insert(exercise.name)
                    routine.exercises.append(exercise)
                }
                routines.append(routine)
            }
        }
        
        return routines
    }
    
    private func scaleExercise(_ base: Exercise, factor: Double) -> Exercise {
        return Exercise(
            name: base.name,
            reps: max(1, Int(Double(base.reps) * factor)),
            sets: base.sets,
            animationModelID: base.animationModelID,
            technicalDescription: base.technicalDescription ?? "",
            instructions: base.instructions ?? [],
            pointsReward: base.pointsReward ?? 10
        )
    }
    
    /// Genera un ejercicio adaptado al deporte específico del usuario para la fase final.
    private func generateSportSpecificExercise(for injury: InjuryProfile) -> Exercise {
        return Exercise(
            name: "Gesto Técnico: \(injury.sport)",
            reps: 15,
            sets: 3,
            animationModelID: "sport_specific",
            technicalDescription: "Adaptación mecánica al \(injury.sport).",
            instructions: ["Imita el gesto deportivo.", "Técnica sobre velocidad."]
        )
    }
    
    private struct TextAnalysis {
        var containsAcuteKeywords: Bool = false
        var containsStructuralKeywords: Bool = false
    }
    
    /// Analiza el texto usando el modelo de MedicalAnalysis (NLP).
    private func analyzeText(_ text: String) -> (containsStructuralKeywords: Bool, containsAcuteKeywords: Bool) {
        let analysis = MedicalAnalysis.analyze(text)
        return (analysis.isStructural, analysis.isAcute)
    }
    
    /// Genera una rutina rápida preventiva de "mantenimiento" diario.
    @MainActor func generatePrehabRoutine(for bodyPart: String) async -> [Exercise] {
        let primary = libraryService.getExercises(for: bodyPart, type: "primary").prefix(1)
        let secondary = libraryService.getExercises(for: bodyPart, type: "secondary").prefix(2)
        
        var exercises: [Exercise] = []
        exercises.append(contentsOf: primary.map { scaleExercise($0, factor: 1.0) })
        exercises.append(contentsOf: secondary.map { scaleExercise($0, factor: 1.0) })
        
        if exercises.isEmpty {
            exercises.append(Exercise(name: "Movilidad Básica", reps: 10, sets: 2, animationModelID: "mob", technicalDescription: "Mantenimiento articular.", instructions: ["Movimiento suave."]))
        }
        
        return exercises
    }
}
