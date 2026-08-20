import Foundation
import Testing

@testable import Cooltour

@MainActor
struct ContentStorePackTests {
  @Test func bundledReseedDoesNotWipeDownloadedPack() throws {
    let store = LocalContentStore.inMemory()
    try store.seedIfNeeded()

    let pack = try JSONDecoder().decode(
      ContentPack.self,
      from: Data(kutaFixtureJSON.utf8)
    )
    try store.install(pack, packID: "kuta")

    #expect(store.allSites().contains { $0.slug == "fixture-kuta-temple" })
    #expect(
      store.allSites().first { $0.slug == "fixture-kuta-temple" }?.packID
        == "kuta"
    )

    try store.seedIfNeeded()

    #expect(store.allSites().contains { $0.slug == "fixture-kuta-temple" })
    #expect(store.allSites().contains { $0.packID == AppConfig.bundledPackID })
    #expect(!store.allSites().contains { $0.slug == "park-23" })
  }

  @Test func uninstallRemovesOnlyThatPack() throws {
    let store = LocalContentStore.inMemory()
    try store.seedIfNeeded()
    let bundledCount = store.siteCount

    let pack = try JSONDecoder().decode(
      ContentPack.self,
      from: Data(kutaFixtureJSON.utf8)
    )
    try store.install(pack, packID: "kuta")
    #expect(store.siteCount == bundledCount + 1)

    try store.uninstall(packID: "kuta")
    #expect(store.siteCount == bundledCount)
    #expect(store.allSites().allSatisfy { $0.packID == AppConfig.bundledPackID })
  }
}

private let kutaFixtureJSON = """
  {
    "contentPackVersion": "1.0.0",
    "region": "Kuta",
    "sites": [
      {
        "slug": "fixture-kuta-temple",
        "name": "Fixture Kuta Temple",
        "district": "Kuta",
        "lat": -8.737,
        "lng": 115.175,
        "triggerRadiusMeters": 40,
        "headingRequired": false,
        "stories": [
          {
            "slug": "fixture-kuta-temple-01",
            "title": "Fixture",
            "audioFile": "fixture.m4a",
            "transcript": "…",
            "durationSeconds": 10,
            "narratorNote": null,
            "timeOfDayTag": null
          }
        ]
      }
    ]
  }
  """
