import Foundation
import NaturalLanguage

/// Motor de análisis médico que utiliza Procesamiento de Lenguaje Natural (NLP).
/// Esta estructura contiene la lógica para interpretar la gravedad de una lesión.
enum MedicalAnalysis {
    // Palabras clave que indican una lesión estructural grave
    static let structuralKeywords: Set<String> = [
        "rotura", "fractura", "grado", "ruptura", "luxación", "tear", "fracture", "grade", "dislocation"
    ]
    
    // Palabras clave que indican un estado agudo o reciente
    static let acuteKeywords: Set<String> = [
        "agudo", "reciente", "fuerte", "agudo", "punzada", "sharp", "acute", "recent", "severe"
    ]
    
    // Síntomas comunes para identificar en el texto
    static let symptomKeywords: Set<String> = [
        "dolor", "inflamación", "tensión", "molestia", "bloqueo", "inestable", "edema", "tendinitis", "irritación",
        "pinchazo", "hormigueo", "debilidad", "crujido", "rigidez"
    ]
    
    // Palabras que atenúan la gravedad
    static let mildKeywords: Set<String> = [
        "leve", "ligero", "pequeño", "mínimo", "estable", "mild", "slight", "stable"
    ]
    
    /// Analiza un texto (informe o descripción) para clasificar la lesión y deducir la parte de cuerpo.
    /// - Parameter text: El texto médico a procesar.
    /// - Returns: Tupla con indicadores de gravedad, síntomas y partes del cuerpo deducidas.
    static func analyze(_ text: String) -> (isStructural: Bool, isAcute: Bool, symptoms: [String], bodyParts: [String]) {
        let tagger = NLTagger(tagSchemes: [.lemma])
        tagger.string = text.lowercased()
        
        var structural = false
        var acute = false
        var mild = false
        var foundSymptoms: Set<String> = []
        var detectedBodyParts: Set<String> = []
        
        let options: NLTagger.Options = [.omitWhitespace, .omitPunctuation, .joinNames]
        
        // 1. Tokenización y Lematización: Buscamos palabras clave en su forma base
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lemma, options: options) { tag, range in
            let word = String(text[range]).lowercased()
            // Si el tagger encuentra la raíz de la palabra la usamos, si no (nil), usamos la palabra literal
            let lemma = tag?.rawValue.lowercased() ?? word
            
            // Chequeos de gravedad médica utilizando el lemma
            if structuralKeywords.contains(lemma) || structuralKeywords.contains(word) { structural = true }
            if acuteKeywords.contains(lemma) || acuteKeywords.contains(word) { acute = true }
            if mildKeywords.contains(lemma) || mildKeywords.contains(word) { mild = true }
            if symptomKeywords.contains(lemma) || symptomKeywords.contains(word) { foundSymptoms.insert(lemma) }
            
            // Chequeos del sistema de diccionarios anatómicos (PUNTO DEBIL 1 MEJORADO)
            if let mappedPart = anatomicalSynonyms[lemma] ?? anatomicalSynonyms[word] {
                detectedBodyParts.insert(mappedPart)
            }
            
            return true
        }
        
        // Comprobación de fuerza bruta por si fallan las lemas con palabras compuestas o frases hechas ("rotura total", "parte baja de la espalda")
        if !structural { structural = structuralKeywords.contains { text.lowercased().contains($0) } }
        if !acute { acute = acuteKeywords.contains { text.lowercased().contains($0) } }
        
        for (synonym, mappedPart) in anatomicalSynonyms {
            // Buscamos si la frase completa contiene el sinónimo coloquial aunque no lo detecte el lema (ej. "gemelo izquierdo")
            if text.lowercased().contains(synonym) {
                detectedBodyParts.insert(mappedPart)
            }
        }
        
        // Si hay palabras "leves", bajamos la bandera de estructural si no hay un daño grave explícito (ej. "pequeña molestia estructural")
        if mild && structural && !text.contains("rotura total") && !text.contains("fractura") {
            structural = false
        }
        
        return (structural, acute, Array(foundSymptoms), Array(detectedBodyParts))
    }
    
    // Diccionario maestro de PNL para mapear palabras coloquiales de pacientes a categorías clínicas exactas
    static let anatomicalSynonyms: [String: String] = [
        "nuca": "cuello", "cervicales": "cuello", "cuello": "cuello", "neck": "cuello", "cervical": "cuello",
        "hombro": "hombro", "manguito": "hombro", "deltoides": "hombro", "rotador": "hombro", "shoulder": "hombro",
        "espalda": "espalda", "lumbares": "lumbar", "lumbar": "lumbar", "riñones": "lumbar", "parte baja de la espalda": "lumbar", "dorsal": "espalda", "back": "espalda",
        "pecho": "pecho", "pectoral": "pecho", "chest": "pecho",
        "brazo": "brazo", "bíceps": "brazo", "biceps": "brazo", "tríceps": "brazo", "triceps": "brazo", "arm": "brazo",
        "codo": "codo", "elbow": "codo", "epicondilitis": "codo",
        "antebrazo": "antebrazo", "muñeca": "muñeca", "wrist": "muñeca", "mano": "muñeca", "carpo": "muñeca", "túnel": "muñeca",
        "barriga": "core", "abdomen": "core", "abdominales": "core", "core": "core", "tripa": "core",
        "cadera": "cadera", "ingle": "cadera", "psoas": "cadera", "glúteo": "cadera", "gluteo": "cadera", "culo": "cadera", "hip": "cadera",
        "pierna": "rodilla", "muslo": "rodilla", "cuádriceps": "rodilla", "cuadriceps": "rodilla", "isquio": "isquio", "isquiotibial": "isquio", "corva": "isquio", "rodilla": "rodilla", "knee": "rodilla",
        "gemelo": "tobillo", "pantorrilla": "tobillo", "sóleo": "tobillo", "soleo": "tobillo",
        "tobillo": "tobillo", "pie": "tobillo", "talón": "tobillo", "talon": "tobillo", "fascitis": "tobillo", "fascia": "tobillo", "ankle": "tobillo"
    ]
    
    /// Estima el tiempo total de recuperación basado en la gravedad y la cronicidad.
    /// - Parameters:
    ///   - isStructural: Si hay daño físico evidente (hueso, tendón).
    ///   - isAcute: Si el dolor es muy reciente o intenso.
    ///   - painLevel: Escala de dolor del usuario.
    ///   - text: Texto para detectar patologías específicas que requieren tiempos distintos.
    /// - Returns: Número estimado de semanas de rehabilitación.
    static func estimateWeeks(isStructural: Bool, isAcute: Bool, painLevel: Int, text: String = "") -> Int {
        let normalized = text.lowercased()
        
        // Casos Especiales de Patología (Lógica de protocolos específicos)
        if normalized.contains("epicondilitis") { return 6 }
        if normalized.contains("túnel carpiano") { return 8 }
        if normalized.contains("fascia") || normalized.contains("plantar") { return 10 }
        if normalized.contains("lumbar") || normalized.contains("lumbalgia") { return 8 }
        
        // Lógica Genérica de Gravedad
        if isStructural {
            return 12 // Casos severos: 12 semanas (fracturas, roturas)
        } else if (isAcute && painLevel > 6) || painLevel > 8 {
            return 8  // Casos moderados/agudos: 8 semanas
        } else if painLevel > 4 {
            return 6  // Casos funcionales: 6 semanas
        } else {
            return 4  // Casos preventivos o leves: 4 semanas
        }
    }
}
