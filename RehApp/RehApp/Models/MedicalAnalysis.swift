import Foundation
import NaturalLanguage

enum MedicalAnalysis {
    static let structuralKeywords: Set<String> = [
        "rotura", "fractura", "grado", "ruptura", "luxación", "tear", "fracture", "grade", "dislocation"
    ]
    
    static let acuteKeywords: Set<String> = [
        "agudo", "reciente", "fuerte", "agudo", "punzada", "sharp", "acute", "recent", "severe"
    ]
    
    static let symptomKeywords: Set<String> = [
        "dolor", "inflamación", "tensión", "molestia", "bloqueo", "inestable", "edema", "tendinitis", "irritación"
    ]
    
    static func analyze(_ text: String) -> (isStructural: Bool, isAcute: Bool, symptoms: [String]) {
        let tagger = NLTagger(tagSchemes: [.lemma])
        tagger.string = text.lowercased()
        
        var structural = false
        var acute = false
        var foundSymptoms: Set<String> = []
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lemma, options: [.omitWhitespace, .omitPunctuation]) { tag, range in
            let word = String(text[range]).lowercased()
            
            if structuralKeywords.contains(word) { structural = true }
            if acuteKeywords.contains(word) { acute = true }
            if symptomKeywords.contains(word) { foundSymptoms.insert(word) }
            
            return true
        }
        
        // Fallback for compound substrings or missing lemmas
        if !structural { structural = structuralKeywords.contains { text.lowercased().contains($0) } }
        if !acute { acute = acuteKeywords.contains { text.lowercased().contains($0) } }
        
        return (structural, acute, Array(foundSymptoms))
    }
    
    static func estimateWeeks(isStructural: Bool, isAcute: Bool, painLevel: Int) -> Int {
        if isStructural {
            return 12 // Severe cases like fractures or ruptures
        } else if isAcute || painLevel > 7 {
            return 6  // Moderate cases with high pain or acute symptoms
        } else {
            return 4  // Minor functional cases (sprains grade 1, etc.)
        }
    }
}
