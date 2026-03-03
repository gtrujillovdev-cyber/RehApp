import XCTest
@testable import RehApp

final class SessionTimerServiceTests: XCTestCase {
    var timerService: SessionTimerService!
    
    override func setUp() {
        super.setUp()
        timerService = SessionTimerService()
    }
    
    func testTimerStartsAndTicks() {
        let expectation = XCTestExpectation(description: "Timer ticks")
        var tickCount = 0
        
        timerService.onTick = { elapsed in
            tickCount += 1
            if tickCount >= 1 {
                expectation.fulfill()
            }
        }
        
        timerService.startTimer(duration: 5)
        
        wait(for: [expectation], timeout: 2.0)
        XCTAssertTrue(timerService.isRunning)
    }
    
    func testTimerCompletion() {
        let expectation = XCTestExpectation(description: "Timer completes")
        
        timerService.onCompletion = {
            expectation.fulfill()
        }
        
        // Use a very short duration for testing completion
        timerService.startTimer(duration: 0.1)
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(timerService.isRunning)
    }
    
    func testPauseResume() {
        timerService.startTimer(duration: 10)
        XCTAssertTrue(timerService.isRunning)
        
        timerService.pauseTimer()
        XCTAssertFalse(timerService.isRunning)
        
        timerService.resumeTimer()
        XCTAssertTrue(timerService.isRunning)
    }
}
