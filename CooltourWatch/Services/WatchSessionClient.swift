import Foundation
import Observation
import WatchConnectivity

/// Watch-side session mirror (Slices 18–21). Holds the latest phone snapshot and reachability.
@MainActor
@Observable
final class WatchSessionClient: NSObject, WCSessionDelegate {
  private(set) var snapshot: WatchSessionSnapshot?
  private(set) var isPhoneReachable = false
  private(set) var isSessionActivated = false

  private let encoder = JSONEncoder()
  private let decoder = JSONDecoder()
  private var lastApproachPromptID: UUID?
  private var lastPlayStartSlug: String?

  /// Fired when Haptic A should play (new prompt id).
  var onApproachHaptic: (() -> Void)?
  /// Fired when Haptic B should play (wayfinding armed / site changed).
  var onPlayStartHaptic: (() -> Void)?

  func activate() {
    guard WCSession.isSupported() else { return }
    let session = WCSession.default
    session.delegate = self
    session.activate()
  }

  func send(_ command: WatchCommand) {
    guard WCSession.isSupported(),
      WCSession.default.activationState == .activated,
      WCSession.default.isReachable
    else { return }
    do {
      let data = try encoder.encode(command)
      WCSession.default.sendMessage([Self.commandKey: data], replyHandler: nil) { _ in }
    } catch {
      // Drop — unreachable phone shows soft unavailable UI; do not invent outcomes.
    }
  }

  func setWalkingMode(_ enabled: Bool) {
    send(.setWalkingMode(enabled))
    // Optimistic local mirror so the toggle feels immediate while WC delivers.
    if var snap = snapshot {
      snap.walkingModeEnabled = enabled
      if !enabled {
        snap.narrationState = .idle
        snap.pendingPrompt = nil
        snap.dismissCountdownSeconds = nil
        snap.wayfindingTarget = nil
        snap.nowPlayingSiteName = nil
        snap.nowPlayingStoryTitle = nil
      }
      apply(snap)
    }
  }

  // MARK: - Private

  private nonisolated static let snapshotKey = "snapshot"
  private nonisolated static let commandKey = "command"

  private func apply(_ snapshot: WatchSessionSnapshot) {
    if let id = WatchHapticPolicy.shouldPlayApproachHaptic(
      previousPromptID: lastApproachPromptID,
      snapshot: snapshot
    ) {
      lastApproachPromptID = id
      onApproachHaptic?()
    }
    if snapshot.pendingPrompt == nil {
      lastApproachPromptID = nil
    }

    if let slug = WatchHapticPolicy.shouldPlayPlayStartHaptic(
      previousTargetSlug: lastPlayStartSlug,
      snapshot: snapshot
    ) {
      lastPlayStartSlug = slug
      onPlayStartHaptic?()
    }
    if snapshot.wayfindingTarget == nil {
      lastPlayStartSlug = nil
    }

    self.snapshot = snapshot
  }

  private func ingestSnapshotData(_ data: Data) {
    guard let snap = try? decoder.decode(WatchSessionSnapshot.self, from: data) else { return }
    apply(snap)
  }

  private func ingestContext(_ context: [String: Any]) {
    guard let data = context[Self.snapshotKey] as? Data else { return }
    ingestSnapshotData(data)
  }

  // MARK: - WCSessionDelegate

  nonisolated func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {
    let reachable = session.isReachable
    let snapshotData = session.receivedApplicationContext[Self.snapshotKey] as? Data
    Task { @MainActor in
      self.isSessionActivated = activationState == .activated
      self.isPhoneReachable = reachable
      if activationState == .activated, let snapshotData {
        self.ingestSnapshotData(snapshotData)
      }
    }
  }

  nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
    let reachable = session.isReachable
    Task { @MainActor in
      self.isPhoneReachable = reachable
    }
  }

  nonisolated func session(
    _ session: WCSession,
    didReceiveApplicationContext applicationContext: [String: Any]
  ) {
    let snapshotData = applicationContext[Self.snapshotKey] as? Data
    Task { @MainActor in
      if let snapshotData {
        self.ingestSnapshotData(snapshotData)
      }
    }
  }
}
