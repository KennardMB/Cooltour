import Foundation
import Observation
import WatchConnectivity

/// Production phone ↔ Watch bridge (Slices 18–24). Pushes latest-wins snapshots; wakes the Watch
/// with a small string plist when a consent prompt opens.
@MainActor
final class WCWatchSessionBridge: NSObject, WatchSessionBridge, WCSessionDelegate {
  private let settings: SettingsStore
  private let narration: any NarrationCoordinator
  private let audio: any AudioPlayerService
  private let proximity: any ProximityEngine

  private var lastPushed: WatchSessionSnapshot?
  /// Coarse key so countdown ticks don't flood wake transfers.
  private var lastTransferredWakeKey: String?
  private var observationTask: Task<Void, Never>?
  private let encoder = JSONEncoder()
  private let decoder = JSONDecoder()

  init(
    settings: SettingsStore,
    narration: any NarrationCoordinator,
    audio: any AudioPlayerService,
    proximity: any ProximityEngine
  ) {
    self.settings = settings
    self.narration = narration
    self.audio = audio
    self.proximity = proximity
    super.init()
  }

  func activate() {
    guard WCSession.isSupported() else { return }
    let session = WCSession.default
    session.delegate = self
    session.activate()
    startObserving()
  }

  func push(_ snapshot: WatchSessionSnapshot) {
    guard snapshot != lastPushed else { return }
    let previous = lastPushed
    lastPushed = snapshot
    guard WCSession.isSupported(), WCSession.default.activationState == .activated else { return }

    do {
      let data = try encoder.encode(snapshot)
      // Latest-wins glance state (including countdown). Base64 keeps the WC dictionary
      // property-list friendly across watchOS versions.
      try WCSession.default.updateApplicationContext([
        Self.snapshotKey: data.base64EncodedString()
      ])
    } catch {
      // Latest-wins; a later refresh will retry.
    }

    deliverWakeIfNeeded(from: previous, to: snapshot)
  }

  func handle(_ command: WatchCommand) {
    switch command {
    case .accept(let id):
      narration.accept(promptID: id)
    case .queue(let id):
      narration.queue(promptID: id)
    case .dismiss(let id):
      narration.dismiss(promptID: id)
    case .setWalkingMode(let enabled):
      settings.walkingMode = enabled
    }
    pushIfNeeded()
  }

  /// Re-read phone state and push when something meaningful changed.
  func pushIfNeeded() {
    applyLeaveRadiusClearIfNeeded()
    push(makeSnapshot())
  }

  // MARK: - Private

  private nonisolated static let snapshotKey = "snapshot"
  private nonisolated static let commandKey = "command"

  private static func wakeKey(for snapshot: WatchSessionSnapshot) -> String {
    let prompt = snapshot.pendingPrompt?.id.uuidString ?? "-"
    let target = snapshot.wayfindingTarget?.siteSlug ?? "-"
    return "\(snapshot.walkingModeEnabled)|\(snapshot.narrationState.rawValue)|\(prompt)|\(target)"
  }

  private func deliverWakeIfNeeded(from previous: WatchSessionSnapshot?, to snapshot: WatchSessionSnapshot) {
    let wakeKey = Self.wakeKey(for: snapshot)
    guard wakeKey != lastTransferredWakeKey else { return }
    lastTransferredWakeKey = wakeKey

    let payload: [String: String]
    if snapshot.narrationState == .prompting, let prompt = snapshot.pendingPrompt {
      payload = WatchWakePayload.approach(
        promptID: prompt.id,
        siteName: prompt.siteName,
        languageCode: snapshot.languageCode
      )
    } else if previous?.pendingPrompt != nil, snapshot.pendingPrompt == nil {
      payload = WatchWakePayload.clear(promptID: previous?.pendingPrompt?.id)
    } else {
      return
    }

    let session = WCSession.default
    guard session.isWatchAppInstalled else { return }

    // Immediate path when the Watch is reachable (often true right after a walk session).
    if session.isReachable {
      session.sendMessage(payload, replyHandler: nil) { _ in
        // Fall through — transferUserInfo already queued below.
      }
    }
    // Queued background delivery; can launch Cooltour Watch briefly to post a local notification.
    session.transferUserInfo(payload)
  }

  private func makeSnapshot() -> WatchSessionSnapshot {
    let story = audio.currentStory
    return WatchSnapshotBuilder.make(
      walkingModeEnabled: settings.walkingMode,
      narrationState: narration.state,
      pendingPrompt: narration.pendingPrompt,
      dismissCountdownSeconds: narration.dismissCountdownSeconds,
      nowPlayingSiteName: story?.site?.name ?? narration.wayfindingTarget?.siteName,
      nowPlayingStoryTitle: story?.title,
      wayfindingTarget: narration.wayfindingTarget,
      languageCode: settings.resolvedLanguageCode
    )
  }

  private func applyLeaveRadiusClearIfNeeded() {
    guard let target = narration.wayfindingTarget else { return }
    let nearby = proximity.nearbySites.map { (slug: $0.id, distanceMeters: $0.distanceMeters) }
    if WayfindingPolicy.shouldClearAfterLeavingRadius(target: target, nearby: nearby) {
      narration.clearWayfindingTarget()
    }
  }

  private func startObserving() {
    observationTask?.cancel()
    observationTask = Task { @MainActor [weak self] in
      while let self, !Task.isCancelled {
        self.pushIfNeeded()
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
          withObservationTracking {
            _ = self.settings.walkingMode
            _ = self.settings.resolvedLanguageCode
            _ = self.narration.state
            _ = self.narration.pendingPrompt
            _ = self.narration.dismissCountdownSeconds
            _ = self.narration.wayfindingTarget
            _ = self.audio.currentStory?.slug
            _ = self.audio.isPlaying
            _ = self.proximity.nearbySites.map(\.id)
            _ = self.proximity.nearbySites.map(\.distanceMeters)
          } onChange: {
            cont.resume()
          }
        }
      }
    }
  }

  // MARK: - WCSessionDelegate

  nonisolated func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {
    Task { @MainActor in
      self.pushIfNeeded()
    }
  }

  nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
  nonisolated func sessionDidDeactivate(_ session: WCSession) {
    session.activate()
  }

  nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
    handleIncomingMessage(message)
  }

  nonisolated func session(
    _ session: WCSession,
    didReceiveMessage message: [String: Any],
    replyHandler: @escaping ([String: Any]) -> Void
  ) {
    handleIncomingMessage(message)
    replyHandler([:])
  }

  nonisolated private func handleIncomingMessage(_ message: [String: Any]) {
    guard let data = message[Self.commandKey] as? Data else { return }
    Task { @MainActor in
      do {
        let command = try self.decoder.decode(WatchCommand.self, from: data)
        self.handle(command)
      } catch {
        // Malformed Watch payloads are ignored — never invent a consent outcome.
      }
    }
  }
}
