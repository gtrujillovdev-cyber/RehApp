import Foundation
import NaturalLanguage

protocol SymptomAnalyzerServiceProtocol: Sendable {
    func extractSymptoms(from text: String) async -> [String]
}

final class SymptomAnalyzerService: SymptomAnalyzerServiceProtocol {
    func extractSymptoms(from text: String) async -> [String] {
        return MedicalAnalysis.analyze(text).symptoms
    }
}
