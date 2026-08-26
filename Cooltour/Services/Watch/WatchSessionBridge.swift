import Foundation

/// Phone-side WatchConnectivity facade. Production (`WCWatchSessionBridge`) arrives in Slice 18.
/// Slice 17 ships the protocol + mock so `AppEnvironment` can inject without activating WC.
@MainActor
protocol WatchSessionBridge: AnyObject {
  /// Push the latest session snapshot to the paired Watch (latest-wins).
  func push(_ snapshot: WatchSessionSnapshot)

  /// Handle a command that arrived from the Watch (or a test injecting one).
  func handle(_ command: WatchCommand)
}

@Observable
final class MockWatchSessionBridge: WatchSessionBridge {
  private(set) var pushedSnapshots: [WatchSessionSnapshot] = []
  private(set) var receivedCommands: [WatchCommand] = []

  /// Optional sink so tests / Slice 18 wiring can observe commands without a real WC session.
  var onCommand: ((WatchCommand) -> Void)?

  func push(_ snapshot: WatchSessionSnapshot) {
    pushedSnapshots.append(snapshot)
  }

  func handle(_ command: WatchCommand) {
    receivedCommands.append(command)
    onCommand?(command)
  }
}
