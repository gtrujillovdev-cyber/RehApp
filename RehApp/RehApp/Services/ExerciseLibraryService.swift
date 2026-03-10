import Foundation

/// Protocolo para el servicio de biblioteca de ejercicios.
protocol ExerciseLibraryServiceProtocol: Sendable {
    func getExercises(for bodyPart: String, type: String?) -> [Exercise]
}

/// Estructura para decodificar el JSON de ejercicios.
private struct ExerciseDTO: Codable {
    let name: String
    let reps: Int
    let sets: Int
    let animationModelID: String
    let technicalDescription: String
    let instructions: [String]
    let bodyParts: [String]
    let type: String
}

private struct ExerciseListDTO: Codable {
    let exercises: [ExerciseDTO]
}

/// Servicio que gestiona el catálogo de ejercicios cargado desde JSON.
final class ExerciseLibraryService: ExerciseLibraryServiceProtocol {
    private let exercises: [ExerciseDTO]
    
    init() {
        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(ExerciseListDTO.self, from: data) else {
            self.exercises = []
            return
        }
        self.exercises = decoded.exercises
    }
    
    func getExercises(for bodyPart: String, type: String? = nil) -> [Exercise] {
        let part = bodyPart.lowercased()
        
        let filtered = exercises.filter { dto in
            let matchesPart = dto.bodyParts.contains { $0 == "general" || part.contains($0) }
            let matchesType = type == nil || dto.type == type
            return matchesPart && matchesType
        }
        
        // Si no hay resultados específicos, devolvemos los generales del tipo solicitado
        if filtered.isEmpty {
            return exercises.filter { $0.bodyParts.contains("general") && (type == nil || $0.type == type) }
                .map { createExercise(from: $0) }
        }
        
        return filtered.map { createExercise(from: $0) }
    }
    
    private func createExercise(from dto: ExerciseDTO) -> Exercise {
        return Exercise(
            name: dto.name,
            reps: dto.reps,
            sets: dto.sets,
            animationModelID: dto.animationModelID,
            technicalDescription: dto.technicalDescription,
            instructions: dto.instructions,
            pointsReward: 10
        )
    }
}
