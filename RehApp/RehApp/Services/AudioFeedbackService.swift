import Foundation
import AVFoundation

protocol AudioFeedbackServiceProtocol: Sendable {
    func speak(_ message: String)
    func playSound(named soundName: String, withExtension ext: String)
    func playFeedback(for event: AudioFeedbackEvent)
}

enum AudioFeedbackEvent {
    case sessionStarted
    case warmUpStarted
    case exerciseStarted(exerciseName: String)
    case exerciseCompleted
    case restStarted
    case coolDownStarted
    case sessionPaused
    case sessionResumed
    case sessionCompleted
    case blockSkipped
    case countdown(Int)
    case pacingGuidance(message: String) // New event
    case formTip(message: String) // New event
}

final class AudioFeedbackService: NSObject, AudioFeedbackServiceProtocol, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?
    
    override init() {
        super.init()
        synthesizer.delegate = self
        // Configure audio session for playback
        #if os(iOS) || os(watchOS) || os(tvOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error.localizedDescription)")
        }
        #endif
    }
    
    func speak(_ message: String) {
        let utterance = AVSpeechUtterance(string: message)
        utterance.voice = AVSpeechSynthesisVoice(language: "es-ES") // Spanish voice
        utterance.rate = 0.5 // Adjust speech rate as needed
        synthesizer.speak(utterance)
    }
    
    func playSound(named soundName: String, withExtension ext: String) {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: ext) else {
            print("Sound file not found: \(soundName).\(ext)")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Could not load or play sound file: \(error.localizedDescription)")
        }
    }
    
    func playFeedback(for event: AudioFeedbackEvent) {
        switch event {
        case .sessionStarted:
            speak("Sesión iniciada.")
        case .warmUpStarted:
            speak("Comienza el calentamiento.")
        case .exerciseStarted(let exerciseName):
            speak("Siguiente ejercicio: \(exerciseName).")
        case .exerciseCompleted:
            speak("Ejercicio completado.")
        case .restStarted:
            speak("Tiempo de descanso.")
        case .coolDownStarted:
            speak("Comienza el enfriamiento.")
        case .sessionPaused:
            speak("Sesión pausada.")
        case .sessionResumed:
            speak("Sesión reanudada.")
        case .sessionCompleted:
            speak("Sesión completada. Buen trabajo.")
        case .blockSkipped:
            speak("Bloque saltado.")
        case .countdown(let number):
            speak("\(number)")
        case .pacingGuidance(let message): // New case
            speak(message)
        case .formTip(let message): // New case
            speak(message)
        }
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // Handle speech completion if needed
    }
}
