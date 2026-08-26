import Foundation
import Testing

@testable import Walkaby

struct WatchSnapshotBuilderTests {
  @Test func builderCopiesAllFields() {
    let promptID = UUID()
    let prompt = PendingPrompt(
      id: promptID,
      siteSlug: "a",
      siteName: "A",
      storySlug: "a-1",
      storyTitle: "Story",
      directionPhrase: nil,
      spokenText: "hi"
    )
    let target = WayfindingTarget(
      siteSlug: "a",
      siteName: "A",
      latitude: 1,
      longitude: 2,
      triggerRadiusMeters: 60
    )
    let snap = WatchSnapshotBuilder.make(
      walkingModeEnabled: true,
      narrationState: .playing,
      pendingPrompt: prompt,
      dismissCountdownSeconds: 3,
      nowPlayingSiteName: "A",
      nowPlayingStoryTitle: "Story",
      wayfindingTarget: target,
      languageCode: "id"
    )
    #expect(snap.walkingModeEnabled)
    #expect(snap.narrationState == .playing)
    #expect(snap.pendingPrompt == prompt)
    #expect(snap.dismissCountdownSeconds == 3)
    #expect(snap.nowPlayingSiteName == "A")
    #expect(snap.wayfindingTarget == target)
    #expect(snap.languageCode == "id")
  }
}

struct WatchHapticPolicyTests {
  private func snapshot(
    state: NarrationState = .idle,
    promptID: UUID? = nil,
    targetSlug: String? = nil
  ) -> WatchSessionSnapshot {
    let prompt: PendingPrompt? = promptID.map {
      PendingPrompt(
        id: $0,
        siteSlug: "s",
        siteName: "S",
        storySlug: "st",
        storyTitle: "T",
        directionPhrase: nil,
        spokenText: "x"
      )
    }
    let target: WayfindingTarget? = targetSlug.map {
      WayfindingTarget(
        siteSlug: $0,
        siteName: "S",
        latitude: 0,
        longitude: 0,
        triggerRadiusMeters: 60
      )
    }
    return WatchSessionSnapshot(
      walkingModeEnabled: true,
      narrationState: state,
      pendingPrompt: prompt,
      dismissCountdownSeconds: promptID == nil ? nil : 5,
      nowPlayingSiteName: nil,
      nowPlayingStoryTitle: nil,
      wayfindingTarget: target,
      languageCode: "en"
    )
  }

  @Test func approachHapticFiresOnNewPromptIDOnly() {
    let id = UUID()
    #expect(
      WatchHapticPolicy.shouldPlayApproachHaptic(
        previousPromptID: nil,
        snapshot: snapshot(state: .prompting, promptID: id)
      ) == id
    )
    #expect(
      WatchHapticPolicy.shouldPlayApproachHaptic(
        previousPromptID: id,
        snapshot: snapshot(state: .prompting, promptID: id)
      ) == nil
    )
    // Countdown-only redelivery (same id) stays silent.
    #expect(
      WatchHapticPolicy.shouldPlayApproachHaptic(
        previousPromptID: id,
        snapshot: snapshot(state: .prompting, promptID: id)
      ) == nil
    )
  }

  @Test func approachHapticSilentWhenNotPrompting() {
    let id = UUID()
    #expect(
      WatchHapticPolicy.shouldPlayApproachHaptic(
        previousPromptID: nil,
        snapshot: snapshot(state: .idle, promptID: id)
      ) == nil
    )
  }

  @Test func playStartHapticFiresOnArmAndSiteChangeNotClear() {
    #expect(
      WatchHapticPolicy.shouldPlayPlayStartHaptic(
        previousTargetSlug: nil,
        snapshot: snapshot(targetSlug: "a")
      ) == "a"
    )
    #expect(
      WatchHapticPolicy.shouldPlayPlayStartHaptic(
        previousTargetSlug: "a",
        snapshot: snapshot(targetSlug: "a")
      ) == nil
    )
    #expect(
      WatchHapticPolicy.shouldPlayPlayStartHaptic(
        previousTargetSlug: "a",
        snapshot: snapshot(targetSlug: "b")
      ) == "b"
    )
    #expect(
      WatchHapticPolicy.shouldPlayPlayStartHaptic(
        previousTargetSlug: "b",
        snapshot: snapshot(targetSlug: nil)
      ) == nil
    )
  }
}

struct WatchApproachNotificationPolicyTests {
  private func snapshot(
    state: NarrationState = .idle,
    promptID: UUID? = nil
  ) -> WatchSessionSnapshot {
    let prompt: PendingPrompt? = promptID.map {
      PendingPrompt(
        id: $0,
        siteSlug: "s",
        siteName: "Pura Maospahit",
        storySlug: "st",
        storyTitle: "T",
        directionPhrase: nil,
        spokenText: "x"
      )
    }
    return WatchSessionSnapshot(
      walkingModeEnabled: true,
      narrationState: state,
      pendingPrompt: prompt,
      dismissCountdownSeconds: promptID == nil ? nil : 5,
      nowPlayingSiteName: nil,
      nowPlayingStoryTitle: nil,
      wayfindingTarget: nil,
      languageCode: "en"
    )
  }

  @Test func postsOnNewPromptIDEvenIfForegroundWouldHaveBlocked() {
    let id = UUID()
    let snap = snapshot(state: .prompting, promptID: id)

    #expect(
      WatchApproachNotificationPolicy.shouldPost(
        previousPromptID: nil,
        snapshot: snap
      )?.id == id
    )
    #expect(
      WatchApproachNotificationPolicy.shouldPost(
        previousPromptID: id,
        snapshot: snap
      ) == nil
    )
  }

  @Test func wakePayloadPostsOnlyOnNewID() {
    let id = UUID()
    #expect(
      WatchApproachNotificationPolicy.shouldPostWake(previousPromptID: nil, promptID: id)
    )
    #expect(
      !WatchApproachNotificationPolicy.shouldPostWake(previousPromptID: id, promptID: id)
    )
  }

  @Test func foregroundHapticOnlyWhenGlanceIsOpen() {
    let id = UUID()
    let snap = snapshot(state: .prompting, promptID: id)

    #expect(
      WatchApproachNotificationPolicy.shouldPlayForegroundHaptic(
        previousPromptID: nil,
        snapshot: snap,
        isAppInForeground: true
      ) == id
    )
    #expect(
      WatchApproachNotificationPolicy.shouldPlayForegroundHaptic(
        previousPromptID: nil,
        snapshot: snap,
        isAppInForeground: false
      ) == nil
    )
  }

  @Test func withdrawsWhenPromptClearsOrChanges() {
    let posted = UUID()
    let other = UUID()

    #expect(
      WatchApproachNotificationPolicy.shouldWithdraw(
        postedPromptID: posted,
        snapshot: snapshot(state: .prompting, promptID: posted)
      ) == nil
    )
    #expect(
      WatchApproachNotificationPolicy.shouldWithdraw(
        postedPromptID: posted,
        snapshot: snapshot(state: .idle, promptID: nil)
      ) == posted
    )
    #expect(
      WatchApproachNotificationPolicy.shouldWithdraw(
        postedPromptID: posted,
        snapshot: snapshot(state: .prompting, promptID: other)
      ) == posted
    )
    #expect(
      WatchApproachNotificationPolicy.shouldWithdraw(
        postedPromptID: nil,
        snapshot: snapshot(state: .idle)
      ) == nil
    )
  }
}

struct WayfindingPolicyTests {
  @Test func leaveRadiusClearsWhenBeyondTriggerOrMissing() {
    let target = WayfindingTarget(
      siteSlug: "pura",
      siteName: "Pura",
      latitude: -8.6,
      longitude: 115.2,
      triggerRadiusMeters: 60
    )
    #expect(
      WayfindingPolicy.shouldClearAfterLeavingRadius(
        target: target,
        nearby: [("pura", 40)]
      ) == false
    )
    #expect(
      WayfindingPolicy.shouldClearAfterLeavingRadius(
        target: target,
        nearby: [("pura", 61)]
      ) == true
    )
    #expect(
      WayfindingPolicy.shouldClearAfterLeavingRadius(
        target: target,
        nearby: [("other", 10)]
      ) == true
    )
  }
}

struct ArrowAngleTests {
  @Test func bearingWraparoundAndQuadrants() {
    // Due north from equator
    let north = ArrowAngle.bearingDegrees(
      fromLatitude: 0,
      fromLongitude: 0,
      toLatitude: 1,
      toLongitude: 0
    )
    #expect(abs(north - 0) < 1 || abs(north - 360) < 1)

    let east = ArrowAngle.bearingDegrees(
      fromLatitude: 0,
      fromLongitude: 0,
      toLatitude: 0,
      toLongitude: 1
    )
    #expect(abs(east - 90) < 1)

    #expect(ArrowAngle.normalizeDegrees(-90) == 270)
    #expect(ArrowAngle.normalizeDegrees(370) == 10)
  }

  @Test func coursePreferredWhileWalkingElseHeadingElseNil() {
    let course = ArrowAngle.trustedHeadingDegrees(
      course: 90,
      courseAccuracy: 10,
      speedMetersPerSecond: 1.2,
      heading: 10,
      headingAccuracy: 5
    )
    #expect(course == 90)

    let heading = ArrowAngle.trustedHeadingDegrees(
      course: 90,
      courseAccuracy: 10,
      speedMetersPerSecond: 0.1,
      heading: 45,
      headingAccuracy: 5
    )
    #expect(heading == 45)

    let none = ArrowAngle.trustedHeadingDegrees(
      course: 90,
      courseAccuracy: -1,
      speedMetersPerSecond: 0,
      heading: 45,
      headingAccuracy: -1
    )
    #expect(none == nil)
  }

  @Test func rotationNilOnBadAccuracy() {
    let rotation = ArrowAngle.rotationDegrees(
      userLatitude: 0,
      userLongitude: 0,
      horizontalAccuracyMeters: 80,
      siteLatitude: 0.001,
      siteLongitude: 0,
      course: 0,
      courseAccuracy: 5,
      speedMetersPerSecond: 1.5,
      heading: 0,
      headingAccuracy: 5
    )
    #expect(rotation == nil)
  }

  @Test func arrowRotationNormalizes() {
    #expect(ArrowAngle.arrowRotationDegrees(bearing: 10, heading: 350) == 20)
    #expect(ArrowAngle.arrowRotationDegrees(bearing: nil, heading: 10) == nil)
  }
}
