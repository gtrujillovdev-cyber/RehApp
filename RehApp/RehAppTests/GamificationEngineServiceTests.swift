import XCTest
import SwiftData
@testable import RehApp

final class GamificationEngineServiceTests: XCTestCase {
    var service: GamificationEngineService!
    var container: ModelContainer!

    @MainActor
    override func setUpWithError() throws {
        let schema = Schema([
            InjuryProfile.self,
            RecoveryRoadmap.self,
            RecoveryPhase.self,
            Exercise.self,
            DailyRoutine.self,
            Milestone.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: config)
        service = GamificationEngineService()
    }

    // MARK: - Tests de integración (processExerciseCompletion)

    @MainActor
    func testProcessExerciseCompletion_SumaRazonamiento() async throws {
        let context = container.mainContext
        let repository = RecoveryRepository(context: context)
        let profile = InjuryProfile(bodyPart: "Rodilla", painLevel: 5, sport: "Ciclismo", symptomsDescription: "")
        let exercise = Exercise(name: "Sentadillas", reps: 10, sets: 3, animationModelID: "", pointsReward: 20)
        let milestone = Milestone(title: "First Step", milestoneDescription: "Test", requiredScore: 15, iconName: "star")

        context.insert(profile)
        context.insert(milestone)

        let newlyUnlocked = try await service.processExerciseCompletion(
            exercise: exercise, profile: profile, repository: repository
        )

        XCTAssertTrue(exercise.isCompleted,           "El ejercicio debe marcarse como completado")
        XCTAssertEqual(profile.recoveryScore, 20,      "Los puntos deben sumarse al perfil")
        XCTAssertEqual(profile.currentStreak, 1,       "Primera sesión → racha arranca en 1")
        XCTAssertNotNil(profile.lastSessionDate,       "Debe guardarse la fecha de la sesión")
        XCTAssertEqual(newlyUnlocked.count, 1,         "El hito (requiredScore 15) debe desbloquearse con score 20")
        XCTAssertEqual(newlyUnlocked.first?.title, "First Step")
    }

    @MainActor
    func testProcessExerciseCompletion_EjercicioYaCompletado_NoHaceNada() async throws {
        let context = container.mainContext
        let repository = RecoveryRepository(context: context)
        let profile = InjuryProfile(bodyPart: "Hombro", painLevel: 3, sport: "Natación", symptomsDescription: "")
        let exercise = Exercise(name: "Péndulo", reps: 20, sets: 3, animationModelID: "", isCompleted: true, pointsReward: 10)

        context.insert(profile)

        let newlyUnlocked = try await service.processExerciseCompletion(
            exercise: exercise, profile: profile, repository: repository
        )

        XCTAssertEqual(profile.recoveryScore, 0, "No deben sumarse puntos si el ejercicio ya estaba completado")
        XCTAssertTrue(newlyUnlocked.isEmpty)
    }

    // MARK: - Tests unitarios de la lógica de racha (función pura)
    //
    // Por qué testeamos la función estática directamente:
    // processExerciseCompletion usa Date() internamente, lo que hace difícil
    // simular "ayer" o "hace 3 días" en un test de integración.
    // Testeando calculateStreak() por separado con fechas controladas tenemos
    // cobertura total de los 4 escenarios sin ningún truco de mocking.

    func testCalculateStreak_SinSesionPrevia_EmpiezaEnUno() {
        let resultado = GamificationEngineService.calculateStreak(
            currentStreak: 0,
            lastSessionDate: nil
        )
        XCTAssertEqual(resultado, 1, "Primera sesión siempre arranca la racha en 1")
    }

    func testCalculateStreak_MismoDia_NoIncrementa() {
        let hoy = Date()
        let resultado = GamificationEngineService.calculateStreak(
            currentStreak: 5,
            lastSessionDate: hoy,
            now: hoy
        )
        XCTAssertEqual(resultado, 5, "Completar varios ejercicios el mismo día no incrementa la racha")
    }

    func testCalculateStreak_DiaSiguiente_Incrementa() {
        let ayer = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let resultado = GamificationEngineService.calculateStreak(
            currentStreak: 3,
            lastSessionDate: ayer
        )
        XCTAssertEqual(resultado, 4, "Sesión al día siguiente debe incrementar la racha")
    }

    func testCalculateStreak_DosOmasDias_Reinicia() {
        let haceDosDias = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        let resultado = GamificationEngineService.calculateStreak(
            currentStreak: 10,
            lastSessionDate: haceDosDias
        )
        XCTAssertEqual(resultado, 1, "Saltar un día debe resetear la racha a 1")
    }

    func testCalculateStreak_UnaSemanaInactivo_Reinicia() {
        let haceUnaSemana = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let resultado = GamificationEngineService.calculateStreak(
            currentStreak: 42,
            lastSessionDate: haceUnaSemana
        )
        XCTAssertEqual(resultado, 1, "Una semana sin sesión debe resetear la racha")
    }

    // MARK: - Tests de múltiples hitos con MockRecoveryRepository
    //
    // Por qué necesitamos MockRecoveryRepository aquí y no SwiftData in-memory:
    // Queremos controlar exactamente qué hitos devuelve fetchMilestones() sin tener
    // que insertar objetos en un contexto SwiftData. Así podemos testear escenarios
    // complejos (varios hitos a diferentes umbrales) de forma directa y legible.

    @MainActor
    func testCheckAndUnlock_SoloDesbloqueanHitosQueSupelanElUmbral() async throws {
        let context    = container.mainContext
        let repository = MockRecoveryRepository()
        let profile    = InjuryProfile(bodyPart: "Rodilla", painLevel: 5, sport: "Ciclismo", symptomsDescription: "")
        context.insert(profile)

        // GIVEN: Tres hitos con umbrales 10, 30 y 50
        let hitoFacil   = Milestone(title: "Principiante", milestoneDescription: "", requiredScore: 10, iconName: "star")
        let hitoMedio   = Milestone(title: "Avanzado",     milestoneDescription: "", requiredScore: 30, iconName: "star.fill")
        let hitoDificil = Milestone(title: "Experto",      milestoneDescription: "", requiredScore: 50, iconName: "trophy")
        repository.storedMilestones = [hitoFacil, hitoMedio, hitoDificil]

        // Un ejercicio que da 25 puntos → score final = 25
        let exercise = Exercise(name: "Flexiones", reps: 10, sets: 3, animationModelID: "", pointsReward: 25)

        // WHEN
        let desbloqueados = try await service.processExerciseCompletion(
            exercise: exercise, profile: profile, repository: repository
        )

        // THEN: Solo el hito de umbral 10 se desbloquea (25 >= 10, pero 25 < 30 y 25 < 50)
        XCTAssertEqual(desbloqueados.count, 1)
        XCTAssertEqual(desbloqueados.first?.title, "Principiante")
        XCTAssertEqual(profile.recoveryScore, 25)
    }

    @MainActor
    func testCheckAndUnlock_HitosYaDesbloqueadosNoSeAnaden() async throws {
        let context    = container.mainContext
        let repository = MockRecoveryRepository()
        let profile    = InjuryProfile(bodyPart: "Hombro", painLevel: 3, sport: "Natación", symptomsDescription: "")
        context.insert(profile)

        // GIVEN: Un hito que el perfil ya tiene desbloqueado
        let hitoExistente = Milestone(title: "Ya ganado", milestoneDescription: "", requiredScore: 5, iconName: "star")
        hitoExistente.isUnlocked = true
        profile.unlockedMilestones.append(hitoExistente) // ya está en el perfil
        repository.storedMilestones = [hitoExistente]

        let exercise = Exercise(name: "Estiramientos", reps: 5, sets: 1, animationModelID: "", pointsReward: 20)

        // WHEN
        let desbloqueados = try await service.processExerciseCompletion(
            exercise: exercise, profile: profile, repository: repository
        )

        // THEN: El hito ya desbloqueado no aparece como nuevo, y no se duplica en el perfil
        XCTAssertTrue(desbloqueados.isEmpty, "Un hito ya desbloqueado no debe aparecer como nuevo")
        XCTAssertEqual(profile.unlockedMilestones.count, 1, "El hito no debe duplicarse")
    }

    @MainActor
    func testCheckAndUnlock_VariosHitosALaVez() async throws {
        let context    = container.mainContext
        let repository = MockRecoveryRepository()
        let profile    = InjuryProfile(bodyPart: "Tobillo", painLevel: 4, sport: "Fútbol", symptomsDescription: "")
        context.insert(profile)

        // GIVEN: Tres hitos cuyos umbrales se superan con un solo ejercicio de 100 puntos
        let hito1 = Milestone(title: "Bronce", milestoneDescription: "", requiredScore: 10,  iconName: "b.circle")
        let hito2 = Milestone(title: "Plata",  milestoneDescription: "", requiredScore: 50,  iconName: "p.circle")
        let hito3 = Milestone(title: "Oro",    milestoneDescription: "", requiredScore: 100, iconName: "o.circle")
        repository.storedMilestones = [hito1, hito2, hito3]

        let exercise = Exercise(name: "Sprint", reps: 1, sets: 1, animationModelID: "", pointsReward: 100)

        // WHEN
        let desbloqueados = try await service.processExerciseCompletion(
            exercise: exercise, profile: profile, repository: repository
        )

        // THEN: Los tres hitos se desbloquean en un solo paso
        XCTAssertEqual(desbloqueados.count, 3)
        XCTAssertEqual(profile.unlockedMilestones.count, 3)
        // Verificamos que todos tienen fecha de desbloqueo
        XCTAssertTrue(desbloqueados.allSatisfy { $0.unlockedAt != nil })
    }
}
