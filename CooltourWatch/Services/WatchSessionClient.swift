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
  /// True while the Watch UI is active — used for custom Haptic A only.
  var isAppInForeground = false

  private let encoder = JSONEncoder()
  private let decoder = JSONDecoder()
  private let notifications: any WatchApproachNotifying
  private var lastApproachPromptID: UUID?
  private var lastPostedNotificationID: UUID?
  private var lastPlayStartSlug: String?

  var onApproachHaptic: (() -> Void)?
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
    } else if session.activationState == .activated {
      isSessionActivated = true
      isPhoneReachable = session.isReachable
      if let data = Self.snapshotData(from: session.receivedApplicationContext) {
        ingestSnapshotData(data)
      }
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
      snapshot: snapshot
    ) {
      postApproach(
        promptID: prompt.id,
        siteName: prompt.siteName,
        languageCode: snapshot.languageCode
      )
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

  private func postApproach(promptID: UUID, siteName: String, languageCode: String) {
    lastApproachPromptID = promptID
    lastPostedNotificationID = promptID
    notifications.postApproach(
      siteName: siteName,
      promptID: promptID,
      languageCode: languageCode
    )
    if isAppInForeground {
      onApproachHaptic?()
    }
  }

  private func handleWakeInfo(_ info: [String: String]) {
    if let clearID = WatchWakePayload.parseClear(info) {
      notifications.withdrawPrompt(id: clearID)
      if lastPostedNotificationID == clearID {
        lastPostedNotificationID = nil
      }
      if lastApproachPromptID == clearID {
        lastApproachPromptID = nil
      }
      return
    }

    guard let approach = WatchWakePayload.parseApproach(info) else { return }
    guard WatchApproachNotificationPolicy.shouldPostWake(
      previousPromptID: lastApproachPromptID,
      promptID: approach.promptID
    ) else { return }

    postApproach(
      promptID: approach.promptID,
      siteName: approach.siteName,
      languageCode: approach.languageCode
    )
  }

  private func ingestSnapshotData(_ data: Data) {
    guard let snap = try? decoder.decode(WatchSessionSnapshot.self, from: data) else { return }
    apply(snap)
  }

  /// Pull Sendable values off WC dictionaries on the callback thread before hopping to MainActor.
  nonisolated private static func snapshotData(from context: [String: Any]) -> Data? {
    if let base64 = context[snapshotKey] as? String {
      return Data(base64Encoded: base64)
    }
    return context[snapshotKey] as? Data
  }

  nonisolated private static func stringInfo(from dictionary: [String: Any]) -> [String: String] {
    var out: [String: String] = [:]
    out.reserveCapacity(dictionary.count)
    for (key, value) in dictionary {
      if let string = value as? String {
        out[key] = string
      }
    }
    return out
  }

  // MARK: - WCSessionDelegate

  nonisolated func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {
    let reachable = session.isReachable
    let data = Self.snapshotData(from: session.receivedApplicationContext)
    Task { @MainActor in
      self.isSessionActivated = activationState == .activated
      self.isPhoneReachable = reachable
      if activationState == .activated, let data {
        self.ingestSnapshotData(data)
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
    let data = Self.snapshotData(from: applicationContext)
    Task { @MainActor in
      if let data {
        self.ingestSnapshotData(data)
      }
    }
  }

  nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
    let info = Self.stringInfo(from: userInfo)
    Task { @MainActor in
      self.handleWakeInfo(info)
    }
  }

  nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
    let info = Self.stringInfo(from: message)
    Task { @MainActor in
      self.handleWakeInfo(info)
    }
  }

  nonisolated func session(
    _ session: WCSession,
    didReceiveMessage message: [String: Any],
    replyHandler: @escaping ([String: Any]) -> Void
  ) {
    let info = Self.stringInfo(from: message)
    replyHandler([:])
    Task { @MainActor in
      self.handleWakeInfo(info)
    }
  }
}
