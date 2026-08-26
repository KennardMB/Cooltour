import MediaPlayer

/// `MPRemoteCommandCenter` / `MPNowPlayingInfoCenter`-backed remote control. Enables `playCommand`
/// only while a prompt is pending so the AirPod stem answers without the phone leaving a pocket,
/// and clears everything on `disarm` so the gesture goes back to the user's music.
final class SystemConsentRemoteControl: ConsentRemoteControl {
  private let commandCenter = MPRemoteCommandCenter.shared()
  private let nowPlaying = MPNowPlayingInfoCenter.default()
  private var playTarget: Any?
  private var togglePlayPauseTarget: Any?
  private var nextTrackTarget: Any?

  func arm(
    title: String,
    onPlay: @escaping () -> Void,
    onQueue: (() -> Void)? = nil
  ) {
    disarm()  // never stack handlers across prompts

    // 1. Single click / squeeze on AirPods: "Play Now"
    let playCommand = commandCenter.playCommand
    playCommand.isEnabled = true
    playTarget = playCommand.addTarget { _ in
      onPlay()
      return .success
    }

    let toggleCommand = commandCenter.togglePlayPauseCommand
    toggleCommand.isEnabled = true
    togglePlayPauseTarget = toggleCommand.addTarget { _ in
      onPlay()
      return .success
    }

    // 2. Double click / double squeeze on AirPods (next track): "Add to Queue"
    if let onQueue {
      let nextCommand = commandCenter.nextTrackCommand
      nextCommand.isEnabled = true
      nextTrackTarget = nextCommand.addTarget { _ in
        onQueue()
        return .success
      }
    }

    nowPlaying.nowPlayingInfo = [
      MPMediaItemPropertyTitle: title,
      MPMediaItemPropertyArtist: AppConfig.appName,
    ]
  }

  func disarm() {
    if let playTarget {
      commandCenter.playCommand.removeTarget(playTarget)
      self.playTarget = nil
    }
    if let togglePlayPauseTarget {
      commandCenter.togglePlayPauseCommand.removeTarget(togglePlayPauseTarget)
      self.togglePlayPauseTarget = nil
    }
    if let nextTrackTarget {
      commandCenter.nextTrackCommand.removeTarget(nextTrackTarget)
      self.nextTrackTarget = nil
      commandCenter.nextTrackCommand.isEnabled = false
    }
    // Only clear nowPlayingInfo and disable commands if it was set for the consent prompt
    // (no playback duration) and not active media playback from the audio player.
    if let currentInfo = nowPlaying.nowPlayingInfo,
      currentInfo[MPMediaItemPropertyPlaybackDuration] == nil
    {
      nowPlaying.nowPlayingInfo = nil
      commandCenter.playCommand.isEnabled = false
      commandCenter.togglePlayPauseCommand.isEnabled = false
    }
  }
}
