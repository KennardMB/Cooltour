import AVFoundation
import Foundation

/// Plays the bundled approach earcon once, then hands off to `PromptVoice`. Kept separate from
/// `AudioPlayerService` so story lifecycle, progress, and queue semantics stay untouched.
@MainActor
protocol ApproachChimePlayer: AnyObject {
  func play(onFinished: @escaping () -> Void)
  func stop()
}

/// Records play/stop calls and invokes the completion immediately by default so coordinator tests
/// stay synchronous unless they opt into manual finish.
final class MockApproachChimePlayer: ApproachChimePlayer {
  private(set) var playCount = 0
  private(set) var stopCount = 0
  private(set) var pendingCompletion: (() -> Void)?
  /// When false, tests must call `finishPlaying()` to simulate the earcon ending.
  var autoFinish = true

  func play(onFinished: @escaping () -> Void) {
    playCount += 1
    pendingCompletion = onFinished
    if autoFinish {
      finishPlaying()
    }
  }

  func stop() {
    stopCount += 1
    pendingCompletion = nil
  }

  /// Test affordance: end the current earcon without going through `stop`.
  func finishPlaying() {
    let completion = pendingCompletion
    pendingCompletion = nil
    completion?()
  }
}

/// Loads `AppConfig.approachChimeAssetName` from the main bundle and plays it through
/// `AVAudioPlayer`. Falls through to `onFinished` immediately when the asset is missing.
@MainActor
final class BundleApproachChimePlayer: NSObject, ApproachChimePlayer, AVAudioPlayerDelegate {
  private var player: AVAudioPlayer?
  private var onFinished: (() -> Void)?

  func play(onFinished: @escaping () -> Void) {
    stop()
    self.onFinished = onFinished

    guard AppConfig.useApproachChime else {
      finish()
      return
    }

    guard
      let url = Bundle.main.url(
        forResource: AppConfig.approachChimeAssetName,
        withExtension: nil
      )
    else {
      print("Approach chime not found: \(AppConfig.approachChimeAssetName)")
      finish()
      return
    }

    do {
      try AVAudioSession.sharedInstance().setActive(true)
      let newPlayer = try AVAudioPlayer(contentsOf: url)
      newPlayer.delegate = self
      newPlayer.prepareToPlay()
      player = newPlayer
      newPlayer.play()
    } catch {
      print("Failed to play approach chime: \(error)")
      finish()
    }
  }

  func stop() {
    player?.stop()
    player = nil
    onFinished = nil
  }

  nonisolated func audioPlayerDidFinishPlaying(
    _ player: AVAudioPlayer,
    successfully flag: Bool
  ) {
    Task { @MainActor in
      self.player = nil
      self.finish()
    }
  }

  private func finish() {
    let completion = onFinished
    onFinished = nil
    completion?()
  }
}
