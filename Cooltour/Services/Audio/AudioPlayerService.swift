import Foundation

protocol AudioPlayerService: AnyObject {
    var isPlaying: Bool { get }
    var rate: Float { get set }
}

@Observable
final class MockAudioPlayerService: AudioPlayerService {
    var isPlaying = false
    var rate: Float = 1.0
}
