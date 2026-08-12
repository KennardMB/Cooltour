import AVFoundation
import Observation

@Observable
@MainActor
final class AVAudioPlayerService: NSObject, AudioPlayerService {
  private(set) var isPlaying: Bool = false
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
    let session = AVAudioSession.sharedInstance()
    do {
      // .playback = audio keeps playing with screen locked / silent switch on
      try session.setCategory(.playback, mode: .spokenAudio)
      try session.setActive(true)
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

    do {
      let newPlayer = try AVAudioPlayer(contentsOf: url)
      newPlayer.enableRate = true  // required before you can change .rate
      newPlayer.rate = rate
      newPlayer.delegate = self
      player = newPlayer

      currentStory = story
      player?.play()
      isPlaying = true
      startProgressTimer()
    } catch {
      print("Failed to play audio: \(error)")
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
  nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
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
