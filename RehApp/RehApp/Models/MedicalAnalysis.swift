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
    
    /// Analiza un texto (informe o descripción) para clasificar la lesión.
    /// - Parameter text: El texto médico a procesar.
    /// - Returns: Una tupla con indicadores de gravedad y lista de síntomas detectados.
    static func analyze(_ text: String) -> (isStructural: Bool, isAcute: Bool, symptoms: [String]) {
        let tagger = NLTagger(tagSchemes: [.lemma]) // Lematización para normalizar palabras
        tagger.string = text.lowercased()
        
        var structural = false
        var acute = false
        var mild = false
        var foundSymptoms: Set<String> = []
        
        // Buscamos palabras clave palabra por palabra
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lemma, options: [.omitWhitespace, .omitPunctuation]) { tag, range in
            let word = String(text[range]).lowercased()
            
            if structuralKeywords.contains(word) { structural = true }
            if acuteKeywords.contains(word) { acute = true }
            if mildKeywords.contains(word) { mild = true }
            if symptomKeywords.contains(word) { foundSymptoms.insert(word) }
            
            return true
        }
        
        // Comprobación adicional por si fallan las lemas con palabras compuestas
        if !structural { structural = structuralKeywords.contains { text.lowercased().contains($0) } }
        if !acute { acute = acuteKeywords.contains { text.lowercased().contains($0) } }
        
        // Si hay palabras "leves", bajamos la bandera de estructural si no es contundente
        if mild && structural && !text.contains("rotura total") {
            structural = false
        }
        
        return (structural, acute, Array(foundSymptoms))
    }
    
    /// Estima el tiempo total de recuperación basado en la gravedad.
    /// - Parameters:
    ///   - isStructural: Si hay daño físico evidente (hueso, tendón).
    ///   - isAcute: Si el dolor es muy reciente o intenso.
    ///   - painLevel: Escala de dolor del usuario.
    /// - Returns: Número estimado de semanas de rehabilitación.
    static func estimateWeeks(isStructural: Bool, isAcute: Bool, painLevel: Int) -> Int {
        if isStructural {
            return 12 // Casos severos: 12 semanas
        } else if isAcute || painLevel > 7 {
            return 6  // Casos moderados: 6 semanas
        } else {
            return 4  // Casos funcionales leves: 4 semanas
        }
    }
}
