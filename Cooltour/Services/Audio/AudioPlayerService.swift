import Foundation

protocol AudioPlayerService {
  var isPlaying: Bool { get }
  var isLoading: Bool { get }
  var currentStory: Story? { get }
  var progress: Double { get }  // 0.0 - 1.0
  var rate: Float { get }

  func play(story: Story)
  func pause()
  func resume()
  func stop()
  func setRate(_ rate: Float)
}
