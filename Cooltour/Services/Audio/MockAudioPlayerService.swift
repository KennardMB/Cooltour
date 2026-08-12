import Foundation
import Observation

@Observable
final class MockAudioPlayerService: AudioPlayerService {
  private(set) var isPlaying: Bool = false
  private(set) var isLoading: Bool = false
  private(set) var currentStory: Story?
  private(set) var progress: Double = 0.0
  private(set) var rate: Float = 1.0

  func play(story: Story) {
    currentStory = story
    isPlaying = true
    progress = 0.3  // pretend it's already 30%
  }

  func pause() {
    isPlaying = false
  }

  func resume() {
    isPlaying = true
  }

  func stop() {
    currentStory = nil
    isPlaying = false
    progress = 0.0
  }

  func setRate(_ newRate: Float) {
    rate = newRate
  }
}
