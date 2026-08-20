import Foundation

protocol AudioPlayerService {
  var isPlaying: Bool { get }
  var isLoading: Bool { get }
  var currentStory: Story? { get }
  var progress: Double { get }  // 0.0 - 1.0
  var rate: Float { get }

  /// Called on the main actor when the current story finishes on its own, so the coordinator can
  /// return to idle and (from Slice 15) offer the next chapter. Nothing consumed this before
  /// Slice 11 — a finished story simply released the session.
  var onPlaybackFinished: (() -> Void)? { get set }

  /// Starts playback for the story in the user's chosen audio language.
  /// - Returns: `false` when the asset is missing (e.g. Indonesian not recorded yet) — callers
  ///   must silence / dismiss rather than falling back to another language.
  @discardableResult
  func play(story: Story) -> Bool
  func pause()
  func resume()
  func stop()
  func setRate(_ rate: Float)
}
