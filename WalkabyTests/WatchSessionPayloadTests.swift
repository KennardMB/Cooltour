import Foundation
import Testing

@testable import Walkaby

/// Slice 17 — WatchConnectivity payloads must survive encode → decode without hardware.
struct WatchSessionPayloadTests {
  private let encoder = JSONEncoder()
  private let decoder = JSONDecoder()

  @Test func fullSnapshotRoundTrips() throws {
    let promptID = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
    let prompt = PendingPrompt(
      id: promptID,
      siteSlug: "pura-maospahit",
      siteName: "Pura Maospahit",
      storySlug: "maospahit-hook",
      storyTitle: "The quiet courtyard",
      directionPhrase: "on your left",
      spokenText: "You're approaching Pura Maospahit, on your left. Press play to hear it."
    )
    let target = WayfindingTarget(
      siteSlug: "pura-maospahit",
      siteName: "Pura Maospahit",
      latitude: -8.6562,
      longitude: 115.2167,
      triggerRadiusMeters: 60
    )
    let snapshot = WatchSessionSnapshot(
      walkingModeEnabled: true,
      narrationState: .prompting,
      pendingPrompt: prompt,
      dismissCountdownSeconds: 7,
      nowPlayingSiteName: nil,
      nowPlayingStoryTitle: nil,
      wayfindingTarget: target,
      languageCode: "en"
    )

    let decoded = try decoder.decode(
      WatchSessionSnapshot.self,
      from: try encoder.encode(snapshot)
    )

    #expect(decoded == snapshot)
  }

  @Test func nilTargetAndIdleSnapshotRoundTrips() throws {
    let snapshot = WatchSessionSnapshot(
      walkingModeEnabled: false,
      narrationState: .idle,
      pendingPrompt: nil,
      dismissCountdownSeconds: nil,
      nowPlayingSiteName: nil,
      nowPlayingStoryTitle: nil,
      wayfindingTarget: nil,
      languageCode: "id"
    )

    let decoded = try decoder.decode(
      WatchSessionSnapshot.self,
      from: try encoder.encode(snapshot)
    )

    #expect(decoded == snapshot)
    #expect(decoded.wayfindingTarget == nil)
    #expect(decoded.pendingPrompt == nil)
  }

  @Test func everyWatchCommandRoundTrips() throws {
    let promptID = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
    let commands: [WatchCommand] = [
      .accept(promptID: promptID),
      .queue(promptID: promptID),
      .dismiss(promptID: promptID),
      .setWalkingMode(true),
      .setWalkingMode(false),
    ]

    for command in commands {
      let decoded = try decoder.decode(WatchCommand.self, from: try encoder.encode(command))
      #expect(decoded == command)
    }
  }

  @Test func narrationStateAndPendingPromptAreCodable() throws {
    for state: NarrationState in [.idle, .prompting, .playing] {
      let decoded = try decoder.decode(NarrationState.self, from: try encoder.encode(state))
      #expect(decoded == state)
    }

    let prompt = PendingPrompt(
      id: UUID(),
      siteSlug: "museum-bali",
      siteName: "Museum Bali",
      storySlug: "museum-hook",
      storyTitle: "Courtyard voices",
      directionPhrase: nil,
      spokenText: "You're approaching Museum Bali. Press play to hear it."
    )
    let decoded = try decoder.decode(PendingPrompt.self, from: try encoder.encode(prompt))
    #expect(decoded == prompt)
  }

  @Test func mockWatchSessionBridgeIsInjectable() {
    let bridge = MockWatchSessionBridge()
    #expect(bridge.pushedSnapshots.isEmpty)
    #expect(bridge.receivedCommands.isEmpty)

    let snapshot = WatchSessionSnapshot(
      walkingModeEnabled: true,
      narrationState: .playing,
      pendingPrompt: nil,
      dismissCountdownSeconds: nil,
      nowPlayingSiteName: "Pura Maospahit",
      nowPlayingStoryTitle: "The quiet courtyard",
      wayfindingTarget: nil,
      languageCode: "en"
    )
    bridge.push(snapshot)
    bridge.handle(.setWalkingMode(false))

    #expect(bridge.pushedSnapshots == [snapshot])
    #expect(bridge.receivedCommands == [.setWalkingMode(false)])
  }
}
