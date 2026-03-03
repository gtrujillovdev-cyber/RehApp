import Foundation
import NaturalLanguage

protocol SymptomAnalyzerServiceProtocol: Sendable {
    func extractSymptoms(from text: String) async -> [String]
}

final class SymptomAnalyzerService: SymptomAnalyzerServiceProtocol {
    func extractSymptoms(from text: String) async -> [String] {
        let tagger = NLTagger(tagSchemes: [.nameTypeOrLexicalClass])
        tagger.string = text
        
        var symptoms: [String] = []
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameTypeOrLexicalClass, options: options) { tag, tokenRange in
            let word = String(text[tokenRange])
            if isSymptomCandidate(word) {
                symptoms.append(word)
            }
            return true
        }
        
        return Array(Set(symptoms))
    }
    
    private func isSymptomCandidate(_ word: String) -> Bool {
        let lowercased = word.lowercased()
        let targets = [
            "dolor", "inflamación", "rotura", "esguince", "tensión", "molestia",
            "agudo", "crónico", "punzada", "bloqueo", "inestable", "edema",
            "tendinitis", "fractura", "luxación", "irritación"
        ]
        return targets.contains { lowercased.contains($0) }
    }
}
