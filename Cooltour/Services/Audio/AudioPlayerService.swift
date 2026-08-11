import Foundation

@MainActor
protocol AudioPlayerService: AnyObject {
    var isPlaying: Bool { get }
    var rate: Float { get set }
    var currentStory: Story? { get }
    func play(_ story: Story)
}

/// Still a mock: real AVFoundation playback is Slice 2. Proximity only needs somewhere to
/// hand the story it picked, and a record of what it asked for.
@Observable
final class MockAudioPlayerService: AudioPlayerService {
    var isPlaying = false
    var rate: Float = 1.0
    private(set) var currentStory: Story?

    func play(_ story: Story) {
        currentStory = story
        isPlaying = true
    }
}
