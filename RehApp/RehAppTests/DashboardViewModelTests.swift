import XCTest
import SwiftData
@testable import RehApp

/// Tests unitarios de DashboardViewModel.
///
/// Por qué usamos MockRecoveryRepository aquí y no RecoveryRepository con SwiftData in-memory:
///
/// 1. ESCENARIOS DE ERROR — SwiftData in-memory nunca falla "a propósito". No podemos
///    pedirle que lance un error en el próximo fetch. Con el mock activamos
///    `shouldThrowOnFetch = true` y tenemos cobertura total del error handling.
///
/// 2. ESPÍAS — Verificamos que el ViewModel llamó al repositorio exactamente el número
///    de veces correcto y con el argumento correcto. SwiftData no expone eso.
///
/// 3. VELOCIDAD — El mock no inicializa ningún stack de base de datos, es instantáneo.
///
/// POR QUÉ EL CONTAINER ES ESTÁTICO:
/// Crear y destruir un ModelContainer por test provoca un double-free interno de SwiftData
/// (crash "malloc: pointer being freed was not allocated" en la misma dirección fija).
/// La causa raíz: DashboardViewModel.init lanza una Task async que mantiene vivo el ViewModel
/// (y sus referencias a @Model objects) después de que tearDown destruye el container.
/// Usar un container estático (vive todo el proceso) garantiza que los objetos @Model
/// siempre tengan un backing store válido cuando Swift los libera.
@MainActor
final class DashboardViewModelTests: XCTestCase {

    var viewModel: DashboardViewModel!
    var mockRepository: MockRecoveryRepository!
    var mockInference: MockInferenceService!

    // Container compartido para todos los tests de esta clase.
    // Se inicializa la primera vez que se accede (lazy) desde el main actor.
    // NUNCA se destruye entre tests — solo se limpian los objetos insertados.
    private static var _container: ModelContainer?
    private static var container: ModelContainer {
        if let c = _container { return c }
        let schema = Schema([
            InjuryProfile.self,
            RecoveryRoadmap.self,
            RecoveryPhase.self,
            Exercise.self,
            DailyRoutine.self,
            Milestone.self
        ])
        let c = try! ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        _container = c
        return c
    }

    var context: ModelContext { Self.container.mainContext }

    override func setUpWithError() throws {
        // Limpiamos los objetos del test anterior sin destruir el container.
        // delete(model:) borra todas las instancias del tipo del contexto en memoria.
        try context.delete(model: InjuryProfile.self)
        try context.delete(model: RecoveryRoadmap.self)
        try context.delete(model: Exercise.self)

        mockRepository = MockRecoveryRepository()
        mockInference   = MockInferenceService()
        viewModel = DashboardViewModel(repository: mockRepository, inferenceService: mockInference)
    }

    override func tearDownWithError() throws {
        // Liberamos las referencias de test. El container NO se destruye.
        viewModel      = nil
        mockRepository = nil
        mockInference  = nil
    }

    // MARK: - selectProfile

    func testSelectProfile_ActualizaRoadmapYLlamaPrehab() async {
        // GIVEN: Un perfil con un roadmap. Insertamos en el context compartido para
        // que SwiftData pueda gestionar la relación de forma segura.
        let profile = InjuryProfile(bodyPart: "Hombro", painLevel: 3, sport: "Natación", symptomsDescription: "")
        let roadmap  = RecoveryRoadmap(estimatedWeeks: 6)
        context.insert(profile)
        context.insert(roadmap)
        profile.roadmaps.append(roadmap)

        // WHEN
        viewModel.selectProfile(profile)

        // THEN: La selección y el roadmap se actualizan síncronamente
        XCTAssertEqual(viewModel.selectedProfile?.id, profile.id)
        XCTAssertEqual(viewModel.currentRoadmap?.id,  roadmap.id)

        // AND: Esperamos 100ms para que la Task async de prehab complete antes de que
        // tearDown corra. Si no awaiteamos, la Task puede seguir viva y el ViewModel
        // queda retenido cuando se liberan las referencias en tearDown.
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(mockInference.generatePrehabCalled)
        XCTAssertEqual(mockInference.lastBodyPartReceived, "Hombro")
    }

    // MARK: - fetchLatestData

    func testFetchLatestData_ConPerfiles_LosExpone() async {
        // GIVEN: Dos perfiles insertados en el context compartido
        let perfil1 = InjuryProfile(bodyPart: "Rodilla", painLevel: 5, sport: "Fútbol",   symptomsDescription: "")
        let perfil2 = InjuryProfile(bodyPart: "Hombro",  painLevel: 3, sport: "Natación", symptomsDescription: "")
        context.insert(perfil1)
        context.insert(perfil2)
        mockRepository.storedProfiles = [perfil1, perfil2]

        // WHEN
        viewModel.fetchLatestData()
        // Dejamos correr la Task de prehab antes de tearDown
        try? await Task.sleep(nanoseconds: 50_000_000)

        // THEN
        XCTAssertEqual(viewModel.allProfiles.count, 2)
        XCTAssertNil(viewModel.errorMessage, "Sin error el mensaje debe ser nil")
    }

    func testFetchLatestData_CuandoElRepositorioFalla_EstableceErrorMessage() {
        // GIVEN: El repositorio va a lanzar un error en el próximo fetch.
        // Este escenario es IMPOSIBLE de testear con SwiftData in-memory real.
        mockRepository.shouldThrowOnFetch = true

        // WHEN
        viewModel.fetchLatestData()

        // THEN: El ViewModel expone el error y deja la lista vacía (no crash silencioso)
        XCTAssertNotNil(viewModel.errorMessage,      "Debe haber un mensaje de error visible")
        XCTAssertTrue(viewModel.allProfiles.isEmpty, "Si el fetch falla la lista debe quedar vacía")
    }

    // MARK: - addInjuryProfile

    func testAddInjuryProfile_LlamaAlRepositorioYSeleccionaElPerfil() async {
        // GIVEN
        let perfil = InjuryProfile(bodyPart: "Tobillo", painLevel: 4, sport: "Baloncesto", symptomsDescription: "")
        context.insert(perfil)

        // WHEN
        viewModel.addInjuryProfile(perfil)
        try? await Task.sleep(nanoseconds: 50_000_000)

        // THEN: El repositorio recibió exactamente una llamada de guardado
        XCTAssertEqual(mockRepository.saveProfileCallCount, 1,
                       "saveInjuryProfile debe llamarse exactamente una vez")
        XCTAssertEqual(mockRepository.lastSavedProfile?.id, perfil.id)

        // AND: El perfil guardado queda seleccionado en la UI
        XCTAssertEqual(viewModel.selectedProfile?.id, perfil.id)
    }

    func testAddInjuryProfile_CuandoElRepositorioFalla_EstableceErrorMessage() {
        // GIVEN
        mockRepository.shouldThrowOnSave = true
        let perfil = InjuryProfile(bodyPart: "Muñeca", painLevel: 2, sport: "Tenis", symptomsDescription: "")
        context.insert(perfil)

        // WHEN
        viewModel.addInjuryProfile(perfil)

        // THEN: El error se comunica al usuario
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(mockRepository.saveProfileCallCount, 0,
                       "Con shouldThrowOnSave el save interrumpe antes de incrementar el contador")
    }

    // MARK: - deleteInjuryProfile

    func testDeleteInjuryProfile_EliminaDelRepositorioYLimpiaSelecion() async {
        // GIVEN: Un perfil almacenado y seleccionado activamente
        let perfil = InjuryProfile(bodyPart: "Cadera", painLevel: 6, sport: "Running", symptomsDescription: "")
        context.insert(perfil)
        mockRepository.storedProfiles = [perfil]
        viewModel.fetchLatestData()
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(viewModel.selectedProfile?.id, perfil.id, "Precondición: el perfil debe estar seleccionado")

        // WHEN
        viewModel.deleteInjuryProfile(perfil)

        // THEN: El repositorio registró la eliminación con el argumento correcto
        XCTAssertEqual(mockRepository.deleteProfileCallCount, 1)
        XCTAssertEqual(mockRepository.lastDeletedProfile?.id, perfil.id)

        // AND: Sin más perfiles, la selección se limpia
        XCTAssertNil(viewModel.selectedProfile)
    }

    // MARK: - stats (propiedad calculada)

    func testStats_DevuelveValoresDelPerfilSeleccionado() async {
        // GIVEN
        let perfil = InjuryProfile(bodyPart: "Espalda", painLevel: 7, sport: "Ciclismo", symptomsDescription: "")
        context.insert(perfil)
        perfil.recoveryScore = 150
        perfil.currentStreak = 7

        // WHEN
        viewModel.selectProfile(perfil)
        try? await Task.sleep(nanoseconds: 50_000_000)

        // THEN
        XCTAssertEqual(viewModel.stats.score,  150, "stats.score debe reflejar recoveryScore del perfil")
        XCTAssertEqual(viewModel.stats.streak,   7, "stats.streak debe reflejar currentStreak del perfil")
    }

    func testStats_SinPerfilSeleccionado_DevuelveCeros() {
        // GIVEN: ViewModel sin ningún perfil cargado
        XCTAssertNil(viewModel.selectedProfile)

        // THEN: Las stats retornan 0 (nil-coalescing), nunca crash
        XCTAssertEqual(viewModel.stats.score,  0)
        XCTAssertEqual(viewModel.stats.streak, 0)
    }
}
