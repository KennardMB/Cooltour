import MediaPlayer

/// `MPRemoteCommandCenter` / `MPNowPlayingInfoCenter`-backed remote control. Enables `playCommand`
/// only while a prompt is pending so the AirPod stem answers without the phone leaving a pocket,
/// and clears everything on `disarm` so the gesture goes back to the user's music.
final class SystemConsentRemoteControl: ConsentRemoteControl {
  private let commandCenter = MPRemoteCommandCenter.shared()
  private let nowPlaying = MPNowPlayingInfoCenter.default()
  private var playTarget: Any?

  func arm(title: String, onPlay: @escaping () -> Void) {
    disarm()  // never stack handlers across prompts

    let command = commandCenter.playCommand
    command.isEnabled = true
    playTarget = command.addTarget { _ in
      onPlay()
      return .success
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
    // Only clear nowPlayingInfo if it was set for the consent prompt (no playback duration)
    // and not active media playback from the audio player.
    if let currentInfo = nowPlaying.nowPlayingInfo,
      currentInfo[MPMediaItemPropertyPlaybackDuration] == nil
    {
      nowPlaying.nowPlayingInfo = nil
    }
  }
}
