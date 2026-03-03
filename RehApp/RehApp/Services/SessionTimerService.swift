import Foundation
import Observation

@MainActor
protocol SessionTimerServiceProtocol: Sendable {
    typealias TickHandler = (TimeInterval) -> Void
    typealias CompletionHandler = () -> Void

    var elapsedTime: TimeInterval { get }
    var isRunning: Bool { get }
    func startTimer(duration: TimeInterval?, onTick: @escaping TickHandler, onComplete: @escaping CompletionHandler)
    func stopTimer()
    func pauseTimer()
    func resumeTimer()
}

@MainActor
@Observable
final class SessionTimerService: SessionTimerServiceProtocol {
    var elapsedTime: TimeInterval = 0
    var isRunning: Bool = false
    private var timer: Timer?
    private var currentDuration: TimeInterval?
    
    @ObservationIgnored private var onTick: TickHandler?
    @ObservationIgnored private var onComplete: CompletionHandler?
    
    func startTimer(duration: TimeInterval?, onTick: @escaping TickHandler, onComplete: @escaping CompletionHandler) {
        stopTimer()
        self.elapsedTime = 0
        self.currentDuration = duration
        self.onTick = onTick
        self.onComplete = onComplete
        self.isRunning = true
        
        scheduleTimer()
    }
    
    private func scheduleTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.elapsedTime += 1
                self.onTick?(self.elapsedTime)
                
                if let duration = self.currentDuration, self.elapsedTime >= duration {
                    self.stopTimer()
                    self.onComplete?()
                }
            }
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
    
    func pauseTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
    
    func resumeTimer() {
        guard !isRunning else { return }
        isRunning = true
        scheduleTimer()
    }
}
