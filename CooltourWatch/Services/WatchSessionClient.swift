import Foundation
import Observation
import WatchConnectivity

/// Watch-side session mirror (Slices 18–24). Holds the latest phone snapshot and reachability.
@MainActor
@Observable
final class WatchSessionClient: NSObject, WCSessionDelegate {
  private(set) var snapshot: WatchSessionSnapshot?
  private(set) var isPhoneReachable = false
  private(set) var isSessionActivated = false
  /// True while the Watch UI is active. Approach notifications fire only when this is false
  /// (Slice 22–24); foreground uses the in-app consent card + custom Haptic A instead.
  var isAppInForeground = false

  private let encoder = JSONEncoder()
  private let decoder = JSONDecoder()
  private let notifications: any WatchApproachNotifying
  private var lastApproachPromptID: UUID?
  private var lastPostedNotificationID: UUID?
  private var lastPlayStartSlug: String?

  /// Fired when Haptic A should play (new prompt id) while the Watch app is foreground.
  var onApproachHaptic: (() -> Void)?
  /// Fired when Haptic B should play (wayfinding armed / site changed).
  var onPlayStartHaptic: (() -> Void)?

  init(notifications: any WatchApproachNotifying = WatchApproachNotificationService()) {
    self.notifications = notifications
    super.init()
  }

  func activate() {
    guard WCSession.isSupported() else { return }
    let session = WCSession.default
    session.delegate = self
    if session.activationState == .notActivated {
      session.activate()
    }
    notifications.requestAuthorizationIfNeeded()
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
    if let withdrawID = WatchApproachNotificationPolicy.shouldWithdraw(
      postedPromptID: lastPostedNotificationID,
      snapshot: snapshot
    ) {
      notifications.withdrawPrompt(id: withdrawID)
      lastPostedNotificationID = nil
    }

    if let prompt = WatchApproachNotificationPolicy.shouldPost(
      previousPromptID: lastApproachPromptID,
      snapshot: snapshot,
      isAppInForeground: isAppInForeground
    ) {
      lastApproachPromptID = prompt.id
      lastPostedNotificationID = prompt.id
      notifications.postPrompt(prompt, languageCode: snapshot.languageCode)
    } else if let id = WatchApproachNotificationPolicy.shouldPlayForegroundHaptic(
      previousPromptID: lastApproachPromptID,
      snapshot: snapshot,
      isAppInForeground: isAppInForeground
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

  nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
    let snapshotData = userInfo[Self.snapshotKey] as? Data
    Task { @MainActor in
      if let snapshotData {
        self.ingestSnapshotData(snapshotData)
      }
    }
  }
}
