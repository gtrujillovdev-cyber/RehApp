import Foundation

protocol ProtocolServiceProtocol: Sendable {
    func loadProtocol(named filename: String) -> ClinicalProtocol?
    func loadProtocol(for injuryType: String) -> ClinicalProtocol?
}

/// Servicio encargado de cargar los protocolos clínicos estandarizados desde archivos JSON.
final class ProtocolService: ProtocolServiceProtocol {
    static let shared = ProtocolService()
    
    func loadProtocol(named filename: String) -> ClinicalProtocol? {
        // En primer lugar, se busca en el Bundle principal (necesita estar añadido al target de Xcode)
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            print("ProtocolService: No se encontró el archivo \(filename).json en el Bundle.")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let decodedProtocol = try decoder.decode(ClinicalProtocol.self, from: data)
            return decodedProtocol
        } catch {
            print("ProtocolService: Error decodificando \(filename).json: \(error)")
            return nil
        }
    }
    
    /// Confiere una capa de seguridad para mapear lo que escribe el usuario
    /// o lo que seleccionó en Onboarding con el archivo JSON físico adecuado.
    func loadProtocol(for injuryType: String) -> ClinicalProtocol? {
        let normalized = injuryType.lowercased().folding(options: .diacriticInsensitive, locale: .current).trimmingCharacters(in: .whitespaces)
        var filename = ""
        
        switch normalized {
        case _ where normalized.contains("condromalacia"):
            filename = "condromalacia_protocol"
        case _ where normalized.contains("esguince") && normalized.contains("tobillo"):
            filename = "ankle_sprain_protocol"
        case _ where normalized.contains("aquilea") || normalized.contains("tendinopat"):
            filename = "achilles_tendinopathy_protocol"
        case _ where normalized.contains("epicondilitis") || normalized.contains("codo"):
            filename = "epicondylitis_protocol"
        case _ where normalized.contains("lumbalgia") || normalized.contains("espalda baja") || normalized.contains("lumbar"):
            filename = "low_back_pain_protocol"
        case _ where normalized.contains("cervicalgia") || normalized.contains("cuello") || normalized.contains("nuca"):
            filename = "cervicalgia_protocol"
        case _ where normalized.contains("fascia") || normalized.contains("plantar") || normalized.contains("talon"):
            filename = "plantar_fasciitis_protocol"
        case _ where normalized.contains("tunel carpiano") || (normalized.contains("hormigueo") && normalized.contains("mano")):
            filename = "carpal_tunnel_protocol"
        default:
            // Si el mapeo falla, devolvemos nil
            print("ProtocolService: No se detectó protocolo exacto para '\(injuryType)'.")
            return nil
        }
        
        return loadProtocol(named: filename)
    }
}
