import CoreLocation
import Foundation
import Testing

@testable import Cooltour

struct PackRegionEvaluatorTests {
  private let pack = RemotePack(
    id: "kuta",
    name: "Kuta",
    version: "1.0.0",
    sizeBytes: 1,
    zipPath: "Packs/kuta/1.0.0",
    latitude: -8.737,
    longitude: 115.175,
    radiusMeters: 8000
  )

  @Test func firesOnceOnEntry() {
    var evaluator = PackRegionEvaluator()
    let inside = CLLocation(latitude: -8.737, longitude: 115.175)
    let first = evaluator.evaluate(packs: [pack], at: inside)
    #expect(first.map(\.id) == ["kuta"])
    let second = evaluator.evaluate(packs: [pack], at: inside)
    #expect(second.isEmpty)
  }

  @Test func rearmsAfterLeavingTheRing() {
    var evaluator = PackRegionEvaluator()
    let inside = CLLocation(latitude: -8.737, longitude: 115.175)
    _ = evaluator.evaluate(packs: [pack], at: inside)

    // ~20 km north — well past 8 km * 1.35
    let outside = CLLocation(latitude: -8.55, longitude: 115.175)
    _ = evaluator.evaluate(packs: [pack], at: outside)

    let again = evaluator.evaluate(packs: [pack], at: inside)
    #expect(again.map(\.id) == ["kuta"])
  }
}

struct PackPromptCooldownTests {
  @Test func ignoreSuppressesFor24Hours() {
    var cooldown = PackPromptCooldown()
    let now = Date(timeIntervalSince1970: 1_000_000)
    cooldown.recordIgnore(packID: "kuta", now: now)
    #expect(cooldown.shouldPrompt(packID: "kuta", now: now.addingTimeInterval(60)) == false)
    #expect(
      cooldown.shouldPrompt(packID: "kuta", now: now.addingTimeInterval(24 * 60 * 60 + 1))
        == true
    )
  }

  @Test func notNowLastsUntilWalkEnds() {
    var cooldown = PackPromptCooldown()
    cooldown.recordNotNow(packID: "kuta")
    #expect(cooldown.shouldPrompt(packID: "kuta") == false)
    cooldown.endWalk()
    #expect(cooldown.shouldPrompt(packID: "kuta") == true)
  }
}
