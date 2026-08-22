import Foundation
import Observation

@Observable
final class MockAudioPlayerService: AudioPlayerService {
  private(set) var isPlaying: Bool = false
  private(set) var isLoading: Bool = false
  private(set) var currentStory: Story?
  private(set) var progress: Double = 0.0
  private(set) var rate: Float = 1.0

  var onPlaybackFinished: (() -> Void)?

  /// Mock has no real duration — treat progress as a 100s track so tests can assert clamps.
  private let fakeDurationSeconds = 100.0

  /// Test affordance: simulate a story reaching its end, driving whatever the coordinator wired.
  func simulatePlaybackFinished() {
    stop()
    onPlaybackFinished?()
  }

  @discardableResult
  func play(story: Story) -> Bool {
    currentStory = story
    isPlaying = true
    progress = 0.0
    return true
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

  func seek(bySeconds deltaSeconds: TimeInterval) {
    guard currentStory != nil else { return }
    seek(toSeconds: progress * fakeDurationSeconds + deltaSeconds)
  }

  func seek(toSeconds seconds: TimeInterval) {
    guard currentStory != nil else { return }
    let newSeconds = min(max(0, seconds), fakeDurationSeconds)
    progress = newSeconds / fakeDurationSeconds
  }
}
