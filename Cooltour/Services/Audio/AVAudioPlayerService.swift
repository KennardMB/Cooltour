import AVFoundation
import Observation

@Observable
@MainActor
final class AVAudioPlayerService: NSObject, AudioPlayerService {
  private(set) var isPlaying: Bool = false
  private(set) var isLoading: Bool = false
  private(set) var currentStory: Story?
  private(set) var progress: Double = 0.0
  private(set) var rate: Float = 1.0

  private var player: AVAudioPlayer?
  private var progressTimer: Timer?

  override init() {
    super.init()
    configureAudioSession()
    handleInterruptionsAndRouteChanges()
  }

  // MARK: - Setup

  private func configureAudioSession() {
    do {
      // .playback = audio keeps playing with screen locked / silent switch on.
      // Only the category here: activating the session interrupts whatever the user is
      // already listening to, so it waits until there's actually a story to play — which
      // also means a background-launched app doesn't activate before it has audio to make.
      try AVAudioSession.sharedInstance().setCategory(
        .playback,
        mode: .spokenAudio
      )
    } catch {
      print("Failed to configure audio session: \(error)")
    }
  }

  // MARK: - Playback controls

  func play(story: Story) {
    guard
      let url = Bundle.main.url(
        forResource: story.audioAssetName,
        withExtension: nil
      )
    else {
      print("Audio file not found: \(story.audioAssetName)")
      return
    }

    self.currentStory = story
    self.isLoading = true

    // A standard Task inherits the @MainActor context of this class
    Task {
      defer { self.isLoading = false }
      do {
        // Hop to the background JUST for the file loading.
        // We only pass `url` (which is Sendable) into the detached closure.
        let sendable = try await Task.detached {
          let player = try AVAudioPlayer(contentsOf: url)
          player.enableRate = true
          player.prepareToPlay()
          return await SendableAudioPlayer(player: player)
        }.value

        let newPlayer = sendable.player

        // We are safely back on the MainActor here. No 'story' or 'self'
        // was captured by the detached task, fixing the Swift 6 data race warnings.
        newPlayer.rate = self.rate
        newPlayer.delegate = self
        self.player = newPlayer
        self.currentStory = story

        // Last possible moment: a load that throws never interrupts the user's music.
        try AVAudioSession.sharedInstance().setActive(true)

        self.player?.play()
        self.isPlaying = true
        self.startProgressTimer()
      } catch {
        print("Failed to play audio: \(error)")
      }
    }
  }

  func pause() {
    player?.pause()
    isPlaying = false
  }

  func resume() {
    player?.play()
    isPlaying = true
  }

  func stop() {
    player?.stop()
    player = nil
    currentStory = nil
    isPlaying = false
    progress = 0.0
    progressTimer?.invalidate()

    // Hand the session back so whatever we interrupted (Spotify, Music, a podcast) can
    // resume — otherwise it stays silently paused until this app is force-quit.
    do {
      try AVAudioSession.sharedInstance().setActive(
        false,
        options: .notifyOthersOnDeactivation
      )
    } catch {
      print("Failed to deactivate audio session: \(error)")
    }
  }

  func setRate(_ newRate: Float) {
    rate = newRate
    player?.rate = newRate
  }

  // MARK: - Progress tracking

  private func startProgressTimer() {
    progressTimer?.invalidate()
    progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) {
      [weak self] _ in
      guard let self else { return }
      Task { @MainActor in
        guard let player = self.player, player.duration > 0 else { return }
        self.progress = player.currentTime / player.duration
      }
    }
  }
}

// MARK: - AVAudioPlayerDelegate & interruption handling

extension AVAudioPlayerService: AVAudioPlayerDelegate {
  /// A story finishing on its own is the only way playback ends today — nothing in the app
  /// calls `stop()` directly — so this is what actually releases the session back to whatever
  /// it interrupted. Reuses `stop()`'s teardown rather than duplicating it; `player?.stop()`
  /// on an already-finished player is a no-op.
  nonisolated func audioPlayerDidFinishPlaying(
    _ player: AVAudioPlayer,
    successfully flag: Bool
  ) {
    Task { @MainActor in
      self.stop()
    }
  }

  private func handleInterruptionsAndRouteChanges() {
    let center = NotificationCenter.default

    center.addObserver(
      forName: AVAudioSession.interruptionNotification,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      guard let self,
        let info = notification.userInfo,
        let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
        let type = AVAudioSession.InterruptionType(rawValue: typeValue)
      else { return }

      switch type {
      case .began:
        Task { @MainActor in
          self.pause()
        }
      case .ended:
        break
      @unknown default:
        break
      }
    }

    center.addObserver(
      forName: AVAudioSession.routeChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      guard let self,
        let info = notification.userInfo,
        let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
        let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue)
      else { return }

      if reason == .oldDeviceUnavailable {
        Task { @MainActor in
          self.pause()
        }
      }
    }
  }
}

private struct SendableAudioPlayer: @unchecked Sendable {
  let player: AVAudioPlayer
}
