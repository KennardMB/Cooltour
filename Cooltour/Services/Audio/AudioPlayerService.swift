import Foundation

@MainActor
protocol AudioPlayerService: AnyObject {
    var isPlaying: Bool { get }
    var rate: Float { get set }
    func play(story: Story)
}

@Observable
@MainActor
final class MockAudioPlayerService: AudioPlayerService {
    var isPlaying = false
    var rate: Float = 1.0
    
    func play(story: Story) {
        print("MockAudioPlayerService: Playing story \(story.title)")
        isPlaying = true
    }
}
