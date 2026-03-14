import Foundation
import CoreML

protocol RehabPhasePredictorServiceProtocol: Sendable {
    func predictRecommendedPhase(injuryType: String, daysSinceInjury: Int, currentPainLevel: Int, previousPhase: Int) -> Int?
}

/// Servicio que interactúa con el modelo CoreML generado por CreateML (RehabPhasePredictor.mlmodel)
/// para recomendar la fase de rehabilitación ideal basada en la evaluación del paciente.
final class RehabPhasePredictorService: RehabPhasePredictorServiceProtocol {
    static let shared = RehabPhasePredictorService()
    
    private lazy var model: MultiRehabPredictor? = {
        do {
            let config = MLModelConfiguration()
            return try MultiRehabPredictor(configuration: config)
        } catch {
            print("Error cargando el modelo CoreML: \(error)")
            return nil
        }
    }()
    
    func predictRecommendedPhase(injuryType: String, daysSinceInjury: Int, currentPainLevel: Int, previousPhase: Int) -> Int? {
        guard let model = model else {
            print("El modelo ML no está disponible. Asegúrese de haber añadido MultiRehabPredictor.mlmodel a Xcode.")
            return nil
        }
        
        do {
            // Usa la clase auto-generada MultiRehabPredictorInput
            let input = MultiRehabPredictorInput(
                injury_type: injuryType,
                days_since_injury: Int64(daysSinceInjury),
                current_pain_level: Int64(currentPainLevel),
                previous_phase: Int64(previousPhase)
            )
            
            let prediction = try model.prediction(input: input)
            return Int(prediction.recommended_phase)
            
        } catch {
            print("Error realizando la predicción clínica: \(error)")
            return nil
        }
    }
}
