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
    private let protocolService: ProtocolServiceProtocol
    
    init(libraryService: ExerciseLibraryServiceProtocol = ExerciseLibraryService(),
         protocolService: ProtocolServiceProtocol = ProtocolService.shared) {
        self.libraryService = libraryService
        self.protocolService = protocolService
    }
    
    @MainActor func generateRoadmap(for injury: InjuryProfile) async -> RecoveryRoadmap {
        // 0. Prioridad Clínica: ¿Existe un Gold Standard Protocol para esto?
        if let clinicalProtocol = protocolService.loadProtocol(for: injury.bodyPart) {
            return generateFromClinicalProtocol(clinicalProtocol, injury: injury)
        }
        
        let reportText = injury.medicalReportText ?? ""
        let symptoms = injury.symptomsDescription
        let combinedText = "\(reportText) \(symptoms)".lowercased()
        
        // 1. Analizar el texto usando NLP avanzado (Mapeo Inteligente)
        let analysis = self.analyzeText(combinedText)
        let isAcute = analysis.containsAcuteKeywords || injury.painLevel > 7
        let isStructural = analysis.containsStructuralKeywords
        
        // 2. Estimar semanas totales de recuperación con contexto ampliado
        let estimatedWeeks = MedicalAnalysis.estimateWeeks(isStructural: isStructural, isAcute: isAcute, painLevel: injury.painLevel, text: combinedText)
        
        let weeksPerPhase = max(1, estimatedWeeks / 4)
        
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
        
        // 4. Crear las 4 Fases de Recuperación integrando el NLP para buscar ejercicios
        let phase1 = self.createPhase(order: 1, title: "Control y Protección", weeks: weeksPerPhase, startWeek: 1, factor: 0.5, injury: injury, mappedBodyParts: analysis.bodyParts)
        let phase2 = self.createPhase(order: 2, title: "Movilidad y Activación", weeks: weeksPerPhase, startWeek: weeksPerPhase + 1, factor: 0.7, injury: injury, mappedBodyParts: analysis.bodyParts)
        let phase3 = self.createPhase(order: 3, title: "Carga Progresiva", weeks: weeksPerPhase, startWeek: (2 * weeksPerPhase) + 1, factor: 0.9, injury: injury, mappedBodyParts: analysis.bodyParts)
        let phase4 = self.createPhase(order: 4, title: "Retorno al Rendimiento", weeks: estimatedWeeks - (3 * weeksPerPhase), startWeek: (3 * weeksPerPhase) + 1, factor: 1.2, injury: injury, mappedBodyParts: analysis.bodyParts)
        
        roadmap.phases = [phase1, phase2, phase3, phase4]
        return roadmap
    }
    
    // MARK: - Evidence-Based Protocol Generation
    
    /// Traduce un Protocolo Clínico estricto cargado desde JSON en las entidades de base de datos interactivas
    private func generateFromClinicalProtocol(_ protocolData: ClinicalProtocol, injury: InjuryProfile) -> RecoveryRoadmap {
        let totalDays = protocolData.phases.reduce(0) { $0 + $1.recommendedDurationDays }
        let estimatedWeeks = max(1, totalDays / 7)
        let roadmap = RecoveryRoadmap(estimatedWeeks: estimatedWeeks)
        
        roadmap.aiReasoning = "Mapeo directo al protocolo estándar de oro: \(protocolData.name). \(protocolData.description) La fase aguda fue evaluada basándonos en tu dolor (\(injury.painLevel)/10)."
        
        var currentWeek = 1
        var phases: [RecoveryPhase] = []
        
        for (index, clinicalPhase) in protocolData.phases.enumerated() {
            let phaseWeeks = max(1, clinicalPhase.recommendedDurationDays / 7)
            let endWeek = currentWeek + phaseWeeks - 1
            let description = "Semanas \(currentWeek)-\(endWeek). \(clinicalPhase.objective)"
            let phase = RecoveryPhase(title: clinicalPhase.name, phaseDescription: description, order: index + 1)
            
            phase.dailyRoutines = generateFixedRoutines(from: clinicalPhase.exercises, injury: injury, phase: index + 1, weeksInPhase: phaseWeeks, startWeek: currentWeek)
            
            phases.append(phase)
            currentWeek += phaseWeeks
        }
        
        roadmap.phases = phases
        return roadmap
    }
    
    private func generateFixedRoutines(from clinicalExercises: [ClinicalExercise], injury: InjuryProfile, phase: Int, weeksInPhase: Int, startWeek: Int) -> [DailyRoutine] {
        var routines: [DailyRoutine] = []
        let dayShortcuts = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]
        let preferredDays = injury.daysPerWeek
        let interval = max(1, 7 / preferredDays)
        
        for week in 0..<weeksInPhase {
            let actualWeek = startWeek + week
            
            for i in 0..<preferredDays {
                let dayIndex = (i * interval) % 7
                let dayTitle = "\(dayShortcuts[dayIndex]) (Semana \(actualWeek))"
                let routine = DailyRoutine(dayTitle: dayTitle, order: (week * preferredDays) + i + 1)
                
                // Mapear los ClinicalExercise a nuestro modelo Exercise interactivo
                var exercisesToInclude: [Exercise] = []
                
                for cExercise in clinicalExercises {
                    let mappedAsset = findAssetForClinicalExercise(cExercise)
                    var instructions = ["Pausa por \(cExercise.holdSeconds)s."]
                    if cExercise.isBilateral { instructions.append("Repetir en ambos lados.") }
                    
                    let ex = Exercise(
                        name: cExercise.name,
                        reps: cExercise.reps,
                        sets: cExercise.sets,
                        animationModelID: mappedAsset,
                        technicalDescription: cExercise.description,
                        instructions: instructions,
                        pointsReward: 15,
                        estimatedDurationPerRep: 4.0 // 4s por repetición para el contador automático
                    )
                    exercisesToInclude.append(ex)
                }
                
                // AJUSTE: Respetar exercisesPerDay del usuario
                let targetCount = injury.exercisesPerDay
                if exercisesToInclude.count > targetCount {
                    // Si hay más ejercicios en el protocolo de los solicitados, tomamos los N primeros (prioridad clínica)
                    routine.exercises = Array(exercisesToInclude.prefix(targetCount))
                } else if exercisesToInclude.count < targetCount {
                    // Si faltan ejercicios, rellenamos con ejercicios del LibraryService (Coach de refuerzo)
                    routine.exercises = exercisesToInclude
                    let extraNeeded = targetCount - exercisesToInclude.count
                    let fallbackExercises = libraryService.getExercises(for: injury.bodyPart, type: "secondary")
                    
                    for _ in 0..<extraNeeded {
                        if let extra = fallbackExercises.randomElement() {
                            routine.exercises.append(scaleExercise(extra, factor: 1.0))
                        }
                    }
                } else {
                    routine.exercises = exercisesToInclude
                }
                
                routines.append(routine)
            }
        }
        return routines
    }
    
    /// Busca un Asset 3D nativo coincidente para el nombre técnico del protocolo
    private func findAssetForClinicalExercise(_ exercise: ClinicalExercise) -> String {
        let name = exercise.name.lowercased()
        if name.contains("isométrico") { return "wall_sit" }
        if name.contains("puente") || name.contains("glúte") { return "bridge" }
        if name.contains("búlgara") || name.contains("lunge") { return "bulgarian_squat" }
        if name.contains("elevación") || name.contains("recta") { return "slr_knee" }
        if name.contains("gato") || name.contains("vaca") { return "exercise_cat_cow" }
        if name.contains("extensión") && name.contains("rodilla") { return "tqe_knee" }
        if name.contains("clamshell") { return "clamshell" }
        if name.contains("inversión") { return "exercise_ankle_inv" }
        if name.contains("cuello") { return "exercise_neck_rot" }
        if name.contains("muñeca") { return "exercise_wrist_flex" }
        if name.contains("remo") { return "exercise_band_row" }
        return "mob"
    }

    private func createPhase(order: Int, title: String, weeks: Int, startWeek: Int, factor: Double, injury: InjuryProfile, mappedBodyParts: [String]) -> RecoveryPhase {
        let endWeek = startWeek + weeks - 1
        let description = "Semanas \(startWeek)-\(endWeek). \(getPhaseBaseDescription(order))"
        let phase = RecoveryPhase(title: title, phaseDescription: description, order: order)
        phase.dailyRoutines = generateDynamicRoutines(for: injury, factor: factor, phase: order, weeksInPhase: weeks, startWeek: startWeek, nlpDetections: mappedBodyParts)
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
    private func generateDynamicRoutines(for injury: InjuryProfile, factor: Double, phase: Int, weeksInPhase: Int, startWeek: Int, nlpDetections: [String]) -> [DailyRoutine] {
        var routines: [DailyRoutine] = []
        let dayShortcuts = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]
        
        let preferredDays = injury.daysPerWeek
        let interval = max(1, 7 / preferredDays)
        
        // Obtenemos ejercicios. Primero usamos el bodyPart literal ingresado, como respaldo de seguridad, iteramos el NLP
        var primaryPool = libraryService.getExercises(for: injury.bodyPart, type: "primary")
        var secondaryPool = libraryService.getExercises(for: injury.bodyPart, type: "secondary")
        
        // Si la cadena literal falla por ser muy coloqual o rara, rellenamos forzosamente con el escaneo de PNL de MedicalAnalysis
        if primaryPool.isEmpty || secondaryPool.isEmpty {
            for detected in nlpDetections {
                let nlpPrimary = libraryService.getExercises(for: detected, type: "primary")
                let nlpSecondary = libraryService.getExercises(for: detected, type: "secondary")
                primaryPool.append(contentsOf: nlpPrimary)
                secondaryPool.append(contentsOf: nlpSecondary)
            }
        }
        
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
            pointsReward: base.pointsReward ?? 10,
            estimatedDurationPerRep: 4.0 // 4s por repetición por defecto
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
            instructions: ["Imita el gesto deportivo.", "Técnica sobre velocidad."],
            estimatedDurationPerRep: 5.0 // Gestos técnicos suelen ser más lentos
        )
    }
    
    private struct TextAnalysis {
        var containsAcuteKeywords: Bool = false
        var containsStructuralKeywords: Bool = false
    }
    
    /// Analiza el texto usando el modelo de MedicalAnalysis (NLP).
    private func analyzeText(_ text: String) -> (containsStructuralKeywords: Bool, containsAcuteKeywords: Bool, bodyParts: [String]) {
        let analysis = MedicalAnalysis.analyze(text)
        return (analysis.isStructural, analysis.isAcute, analysis.bodyParts)
    }
    
    /// Genera una rutina rápida preventiva de "mantenimiento" diario.
    @MainActor func generatePrehabRoutine(for bodyPart: String) async -> [Exercise] {
        let primary = libraryService.getExercises(for: bodyPart, type: "primary").prefix(1)
        let secondary = libraryService.getExercises(for: bodyPart, type: "secondary").prefix(2)
        
        var exercises: [Exercise] = []
        exercises.append(contentsOf: primary.map { scaleExercise($0, factor: 1.0) })
        exercises.append(contentsOf: secondary.map { scaleExercise($0, factor: 1.0) })
        
        if exercises.isEmpty {
            exercises.append(Exercise(name: "Movilidad Básica", reps: 10, sets: 2, animationModelID: "mob", technicalDescription: "Mantenimiento articular.", instructions: ["Movimiento suave."], estimatedDurationPerRep: 4.0))
        }
        
        return exercises
    }
}
