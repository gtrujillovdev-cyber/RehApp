import XCTest
@testable import RehApp

// @MainActor requerido porque SessionTimerService está aislado al actor principal
@MainActor
final class SessionTimerServiceTests: XCTestCase {
    var timerService: SessionTimerService!

    override func setUp() {
        super.setUp()
        timerService = SessionTimerService()
    }

    override func tearDown() {
        // Detenemos el timer al finalizar para no dejar recursos colgados
        timerService.stopTimer()
        timerService = nil
        super.tearDown()
    }

    func testTimerStartsAndTicks() async {
        let expectation = XCTestExpectation(description: "El timer debe emitir al menos un tick")

        // La API actual recibe los closures como parámetros en startTimer, no como propiedades
        timerService.startTimer(duration: 5, onTick: { _ in
            expectation.fulfill()
        }, onComplete: { })

        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertTrue(timerService.isRunning)
        timerService.stopTimer()
    }

    func testTimerCompletion() async {
        let expectation = XCTestExpectation(description: "El timer debe completarse")

        // duration: 0.1 → el timer dispara cada 1s; en el primer tick elapsed(1) >= 0.1, así que completa
        timerService.startTimer(duration: 0.1, onTick: { _ in }, onComplete: {
            expectation.fulfill()
        })

        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertFalse(timerService.isRunning)
    }

    func testPauseResume() {
        timerService.startTimer(duration: 10, onTick: { _ in }, onComplete: { })
        XCTAssertTrue(timerService.isRunning)

        timerService.pauseTimer()
        XCTAssertFalse(timerService.isRunning)

        timerService.resumeTimer()
        XCTAssertTrue(timerService.isRunning)

        timerService.stopTimer()
    }
}
