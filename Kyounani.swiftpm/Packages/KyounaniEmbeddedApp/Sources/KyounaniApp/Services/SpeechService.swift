#if canImport(SwiftUI)
import Foundation

#if canImport(AVFoundation)
import AVFoundation

public final class SpeechService: ObservableObject {
    private let synth = AVSpeechSynthesizer()
    @Published public var selectedVoiceIdentifier: String?

    public init() {}

    public func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = preferredJapaneseVoice()
        utterance.rate = 0.45
        synth.stopSpeaking(at: .immediate)
        synth.speak(utterance)
    }

    public func availableJapaneseVoices() -> [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("ja") }
    }

    private func preferredJapaneseVoice() -> AVSpeechSynthesisVoice? {
        if let selectedVoiceIdentifier,
           let chosen = AVSpeechSynthesisVoice(identifier: selectedVoiceIdentifier) {
            return chosen
        }

        let voices = availableJapaneseVoices()
        if let enhanced = voices.first(where: { $0.quality == .enhanced }) {
            return enhanced
        }
        return AVSpeechSynthesisVoice(language: "ja-JP")
    }
}
#else
public final class SpeechService: ObservableObject {
    public init() {}
    public func speak(_ text: String) {}
}
#endif

#endif
