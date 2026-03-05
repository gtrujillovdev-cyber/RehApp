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
    
    /// Genera una hoja de ruta completa basada en el perfil de la lesión.
    @MainActor func generateRoadmap(for injury: InjuryProfile) async -> RecoveryRoadmap {
        let reportText = injury.medicalReportText ?? ""
        let symptoms = injury.symptomsDescription
        let combinedText = "\(reportText) \(symptoms)".lowercased()
        
        // 1. Analizar el texto usando NLP para detectar gravedad
        let analysis = analyzeText(combinedText)
        let isAcute = analysis.containsAcuteKeywords || injury.painLevel > 7
        let isStructural = analysis.containsStructuralKeywords
        
        // 2. Estimar semanas totales de recuperación
        let estimatedWeeks = MedicalAnalysis.estimateWeeks(isStructural: isStructural, isAcute: isAcute, painLevel: injury.painLevel)
        let roadmap = RecoveryRoadmap(estimatedWeeks: estimatedWeeks)
        
        let weeksPerPhase = max(1, estimatedWeeks / 4)
        
        // 3. Generar el razonamiento de la IA (Explicación para el usuario)
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
        
        // Fase 1: Protección y Control del Dolor
        let p1End = weeksPerPhase
        let phase1 = RecoveryPhase(
            title: "Control y Protección",
            phaseDescription: "Semanas 1-\(p1End). Reducción de inflamación y protección del tejido lesionado. Carga mínima.",
            order: 1
        )
        phase1.dailyRoutines = generateDynamicRoutines(for: injury, factor: 0.5, phase: 1, weeksInPhase: weeksPerPhase)
        
        // Fase 2: Movilidad y Activación Muscular
        let p2Start = p1End + 1
        let p2End = p1End + weeksPerPhase
        let phase2 = RecoveryPhase(
            title: "Movilidad y Activación",
            phaseDescription: "Semanas \(p2Start)-\(p2End). Recuperación del rango de movimiento y activación muscular neuromuscular.",
            order: 2
        )
        phase2.dailyRoutines = generateDynamicRoutines(for: injury, factor: 0.7, phase: 2, weeksInPhase: weeksPerPhase)
        
        // Fase 3: Carga Progresiva (Fortalecimiento)
        let p3Start = p2End + 1
        let p3End = p2End + weeksPerPhase
        let phase3 = RecoveryPhase(
            title: "Carga Progresiva",
            phaseDescription: "Semanas \(p3Start)-\(p3End). Fortalecimiento específico y adaptación a la carga mecánica.",
            order: 3
        )
        phase3.dailyRoutines = generateDynamicRoutines(for: injury, factor: 0.9, phase: 3, weeksInPhase: weeksPerPhase)
        
        // Fase 4: Retorno al Deporte
        let p4Start = p3End + 1
        let p4End = estimatedWeeks
        let phase4 = RecoveryPhase(
            title: "Retorno al Rendimiento",
            phaseDescription: "Semanas \(p4Start)-\(p4End). Gestos técnicos del \(injury.sport) y preparación para el alta competitiva.",
            order: 4
        )
        phase4.dailyRoutines = generateDynamicRoutines(for: injury, factor: 1.2, phase: 4, weeksInPhase: weeksPerPhase)
        
        roadmap.phases = [phase1, phase2, phase3, phase4]
        return roadmap
    }
    
    /// Genera rutinas diarias variadas para cada fase, ajustando la intensidad (factor).
    private func generateDynamicRoutines(for injury: InjuryProfile, factor: Double, phase: Int, weeksInPhase: Int) -> [DailyRoutine] {
        var routines: [DailyRoutine] = []
        let dayShortcuts = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]
        
        let weeksPerPhase = weeksInPhase
        let preferredDays = injury.daysPerWeek
        let interval = max(1, 7 / preferredDays)
        
        // Seleccionamos ejercicios específicos para la zona lesionada
        let primaryPool = getPrimaryPool(for: injury.bodyPart, factor: factor)
        let secondaryPool = getSecondaryPool(for: injury.bodyPart, factor: factor)
        
        for week in 0..<weeksPerPhase {
            let actualWeek = ((phase - 1) * weeksPerPhase) + week + 1
            
            for i in 0..<preferredDays {
                let dayIndex = (i * interval) % 7
                let dayTitle = "\(dayShortcuts[dayIndex]) (Semana \(actualWeek))"
                let routine = DailyRoutine(dayTitle: dayTitle, order: (week * preferredDays) + i + 1)
                
                var usedNames = Set<String>()
                
                for j in 0..<injury.exercisesPerDay {
                    let exercise: Exercise
                    
                    if j == 0 && phase >= 4 {
                        // En la fase final, incluimos el gesto técnico del deporte
                        exercise = generateSportSpecificExercise(for: injury)
                    } else if j % 2 == 0 {
                        let available = primaryPool.filter { !usedNames.contains($0.name) }
                        exercise = copyExercise(available.randomElement() ?? primaryPool.randomElement()!)
                    } else {
                        let available = secondaryPool.filter { !usedNames.contains($0.name) }
                        exercise = copyExercise(available.randomElement() ?? secondaryPool.randomElement()!)
                    }
                    
                    usedNames.insert(exercise.name)
                    routine.exercises.append(exercise)
                }
                routines.append(routine)
            }
        }
        
        return routines
    }
    
    private func copyExercise(_ base: Exercise) -> Exercise {
        return Exercise(
            name: base.name,
            reps: base.reps,
            sets: base.sets,
            animationModelID: base.animationModelID,
            technicalDescription: base.technicalDescription ?? "",
            instructions: base.instructions ?? [],
            pointsReward: base.pointsReward ?? 10
        )
    }
    
    /// Repositorio dinámico de ejercicios según la parte del cuerpo lesionada.
    private func getPrimaryPool(for bodyPart: String, factor: Double) -> [Exercise] {
        let part = bodyPart.lowercased()
        var pool: [Exercise] = []
        
        // Rodilla
        if part.contains("rodilla") || part.contains("knee") {
            pool = [
                Exercise(name: "Flexo-extensión Deslizada", reps: Int(15 * factor), sets: 3, animationModelID: "knee_slide", technicalDescription: "Movilidad pasiva asistida.", instructions: ["Desliza el talón suavemente.", "Mantén 2 segundos."]),
                Exercise(name: "Extensión Terminal (TQE)", reps: Int(12 * factor), sets: 3, animationModelID: "tqe_knee", technicalDescription: "Activación del vasto medial.", instructions: ["Extiende contra la banda.", "Aprieta cuádriceps 2s."]),
                Exercise(name: "Sentadilla Isométrica", reps: 3, sets: 1, animationModelID: "wall_sit", technicalDescription: "Carga isométrica segura.", instructions: ["Espalda contra la pared.", "Mantén 30 segundos."]),
                Exercise(name: "Elevación de Pierna Recta", reps: Int(15 * factor), sets: 3, animationModelID: "slr_knee", technicalDescription: "Fortalecimiento sin carga articular.", instructions: ["Pierna bloqueada.", "Lenta bajada."])
            ]
        } 
        // Hombro
        else if part.contains("hombro") || part.contains("shoulder") {
            pool = [
                Exercise(name: "Péndulo de Codman", reps: Int(20 * factor), sets: 3, animationModelID: "pendulum", technicalDescription: "Descompresión articular.", instructions: ["Brazo relajado.", "Círculos suaves."]),
                Exercise(name: "Rotación Externa con Banda", reps: Int(12 * factor), sets: 3, animationModelID: "ext_rot", technicalDescription: "Estabilidad manguito rotador.", instructions: ["Codo pegado al cuerpo.", "Resistencia controlada."]),
                Exercise(name: "Isométrico de Abducción", reps: 10, sets: 3, animationModelID: "abd_iso", technicalDescription: "Activación deltoidea estática.", instructions: ["Presiona contra la pared.", "Mantén 5 segundos."])
            ]
        } 
        // Genérico (Si la zona no está mapeada)
        else {
            pool = [
                Exercise(name: "Movilidad General", reps: Int(12 * factor), sets: 3, animationModelID: "gen_mob", technicalDescription: "Rango de movimiento funcional.", instructions: ["Movimiento fluido.", "Sin dolor."]),
                Exercise(name: "Activación Neuromuscular", reps: Int(10 * factor), sets: 3, animationModelID: "gen_act", technicalDescription: "Control motor preventivo.", instructions: ["Foco en la técnica.", "Estabilidad total."])
            ]
        }
        return pool
    }
    
    private func getSecondaryPool(for bodyPart: String, factor: Double) -> [Exercise] {
        let part = bodyPart.lowercased()
        var pool: [Exercise] = []
        
        if part.contains("rodilla") || part.contains("knee") {
            pool = [
                Exercise(name: "Puente Glúteo", reps: Int(15 * factor), sets: 3, animationModelID: "bridge", technicalDescription: "Estabilidad posterior.", instructions: ["Eleva cadera.", "Aprieta glúteos."]),
                Exercise(name: "Clamshells (Almejas)", reps: Int(15 * factor), sets: 3, animationModelID: "clamshell", technicalDescription: "Activación glúteo medio.", instructions: ["Rodillas juntas.", "Abre sin rotar pelvis."]),
                Exercise(name: "Plancha Abdominal", reps: 3, sets: 1, animationModelID: "plank", technicalDescription: "Core para estabilidad de carga.", instructions: ["Cuerpo alineado.", "Mantén 30 segundos."])
            ]
        } else {
            pool = [
                Exercise(name: "Estiramiento Dinámico", reps: Int(10 * factor), sets: 2, animationModelID: "dyn_stretch", technicalDescription: "Flexibilidad activa.", instructions: ["Movimiento rítmico.", "No rebotes."]),
                Exercise(name: "Core Stability", reps: Int(12 * factor), sets: 3, animationModelID: "core", technicalDescription: "Protección de cadena cinética.", instructions: ["Ombligo hacia adentro.", "Espalda neutra."])
            ]
        }
        return pool
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
        let factor = 1.0
        let primary = getPrimaryPool(for: bodyPart, factor: factor).prefix(1)
        let secondary = getSecondaryPool(for: bodyPart, factor: factor).prefix(2)
        
        var exercises: [Exercise] = []
        exercises.append(contentsOf: primary.map { copyExercise($0) })
        exercises.append(contentsOf: secondary.map { copyExercise($0) })
        
        if exercises.isEmpty {
            exercises.append(Exercise(name: "Movilidad Básica", reps: 10, sets: 2, animationModelID: "mob", technicalDescription: "Mantenimiento articular.", instructions: ["Movimiento suave."]))
        }
        
        return exercises
    }
}
