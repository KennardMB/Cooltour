import AVFoundation
import MediaPlayer
import Observation

@Observable
@MainActor
final class AVAudioPlayerService: NSObject, AudioPlayerService {
  private(set) var isPlaying: Bool = false
  private(set) var isLoading: Bool = false
  private(set) var currentStory: Story?
  private(set) var progress: Double = 0.0
  private(set) var rate: Float = 1.0

  /// Fires on natural completion so the narration coordinator can advance the queue. Not called
  /// on manual stop or device removal — those are the user (or the world) ending playback, not a
  /// story running out.
  var onPlaybackFinished: (() -> Void)?

  private var player: AVAudioPlayer?
  private var progressTimer: Timer?
  private let settings: SettingsStore

  init(settings: SettingsStore = SettingsStore()) {
    self.settings = settings
    super.init()
    configureAudioSession()
    handleInterruptionsAndRouteChanges()
    configureRemoteCommands()
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

  /// AirPods' Automatic Ear Detection — pause when removed from the ear, resume when put back
  /// in — never touches `AVAudioSession`. It's delivered as a standard system remote command,
  /// the same channel as lock-screen and Control Center controls, so without a target here
  /// none of that reaches us: audio just keeps playing silently into an empty ear.
  private func configureRemoteCommands() {
    let commandCenter = MPRemoteCommandCenter.shared()

    commandCenter.pauseCommand.addTarget { [weak self] _ in
      guard let self, self.isPlaying else { return .commandFailed }
      self.pause()
      return .success
    }

    commandCenter.playCommand.addTarget { [weak self] _ in
      guard let self, self.currentStory != nil, !self.isPlaying else { return .commandFailed }
      self.resume()
      return .success
    }

    commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
      guard let self, self.currentStory != nil else { return .commandFailed }
      self.isPlaying ? self.pause() : self.resume()
      return .success
    }

    commandCenter.stopCommand.addTarget { [weak self] _ in
      guard let self, self.currentStory != nil else { return .commandFailed }
      self.stop()
      return .success
    }

    // Not supported — leaving these enabled would show dead skip buttons on the lock screen.
    commandCenter.nextTrackCommand.isEnabled = false
    commandCenter.previousTrackCommand.isEnabled = false
  }

  // MARK: - Playback controls

  @discardableResult
  func play(story: Story) -> Bool {
    let language = settings.audioLanguage
    guard let assetName = story.audioAssetName(for: language) else {
      print(
        "Audio unavailable for \(language.rawValue): \(story.slug) — staying silent"
      )
      stop()
      return false
    }

    guard
      let url = Bundle.main.url(
        forResource: assetName,
        withExtension: nil
      )
    else {
      print("Audio file not found: \(assetName)")
      stop()
      return false
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
        self.updateNowPlayingInfo()
      } catch {
        print("Failed to play audio: \(error)")
        self.stop()
      }
    }
    return true
  }

  func pause() {
    player?.pause()
    isPlaying = false
    updateNowPlayingInfo()
  }

  func resume() {
    player?.play()
    isPlaying = true
    updateNowPlayingInfo()
  }

  func stop() {
    endPlayback()
  }

  func setRate(_ newRate: Float) {
    rate = newRate
    player?.rate = newRate
    updateNowPlayingInfo()
  }

  func seek(bySeconds deltaSeconds: TimeInterval) {
    guard let player, player.duration > 0 else { return }
    let newTime = min(max(0, player.currentTime + deltaSeconds), player.duration)
    player.currentTime = newTime
    progress = newTime / player.duration
    updateNowPlayingInfo()
  }

  // MARK: - Teardown

  /// The one terminal path: releases the player and hands the session back to whatever we
  /// interrupted (Spotify, Music, a podcast). Called by `stop()`, the finish delegate, and
  /// AirPods disconnecting — every case where playback is actually done, not just paused,
  /// so none of them can leave the session open with nothing using it.
  private func endPlayback() {
    player?.stop()
    player = nil
    currentStory = nil
    isPlaying = false
    progress = 0.0
    progressTimer?.invalidate()
    updateNowPlayingInfo()

    do {
      try AVAudioSession.sharedInstance().setActive(
        false,
        options: .notifyOthersOnDeactivation
      )
    } catch {
      print("Failed to deactivate audio session: \(error)")
    }
  }

  // MARK: - Now Playing (lock screen, Control Center, AirPods ear detection)

  /// The system only has a play/pause target to call — via `configureRemoteCommands` — once
  /// it knows something is playing, and that knowledge comes entirely from this info, not
  /// from the audio session. Cleared (nil `currentStory`/`player`) on every terminal path.
  private func updateNowPlayingInfo() {
    guard let story = currentStory, let activePlayer = player else {
      MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
      return
    }

    let info: [String: Any] = [
      MPMediaItemPropertyTitle: story.title,
      MPMediaItemPropertyArtist: story.site?.name ?? AppConfig.appName,
      MPMediaItemPropertyPlaybackDuration: activePlayer.duration,
      MPNowPlayingInfoPropertyElapsedPlaybackTime: activePlayer.currentTime,
      MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? Double(rate) : 0.0,
    ]
    MPNowPlayingInfoCenter.default().nowPlayingInfo = info
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
  nonisolated func audioPlayerDidFinishPlaying(
    _ player: AVAudioPlayer,
    successfully flag: Bool
  ) {
    Task { @MainActor in
      self.endPlayback()
      // A story reaching its end is the one terminal path the queue should follow on. Notify
      // last, after teardown, so the coordinator advances into a settled player. Manual stop
      // and device removal deliberately don't notify — the user ended playback, not the story.
      self.onPlaybackFinished?()
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
        // Without `.shouldResume` the system is saying don't — e.g. another app took over
        // the session outright — so silence is the correct outcome, not a resume attempt.
        guard
          let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt,
          AVAudioSession.InterruptionOptions(rawValue: optionsValue).contains(.shouldResume)
        else { return }
        Task { @MainActor in
          self.resumeAfterInterruption()
        }
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
        // The output she was listening on is gone — that's her stopping, not a pause to
        // come back from, so this releases the session rather than just muting into it.
        Task { @MainActor in
          self.endPlayback()
        }
      }
    }
  }

  /// `.ended` with `.shouldResume`: the interruption (a phone call) is over and the system
  /// is inviting us back. Our session may have been deactivated for its duration, so it's
  /// reactivated explicitly before asking the player to resume.
  private func resumeAfterInterruption() {
    do {
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      print("Failed to reactivate audio session: \(error)")
    }
    resume()
  }
}

private struct SendableAudioPlayer: @unchecked Sendable {
  let player: AVAudioPlayer
}
