import Foundation
import Testing

@testable import Cooltour

@MainActor
struct PackInstallerTests {
  @Test func missingAudioDoesNotSeedOrLeaveFiles() throws {
    let fm = FileManager.default
    let scratch = fm.temporaryDirectory.appending(
      path: "cooltour-install-\(UUID().uuidString)"
    )
    let source = scratch.appending(path: "source")
    let packsRoot = scratch.appending(path: "Packs")
    try fm.createDirectory(at: source.appending(path: "audio"), withIntermediateDirectories: true)
    try Data(validPackJSON.utf8).write(to: source.appending(path: "kuta.json"))
    // audio/clip.m4a deliberately missing

    let store = LocalContentStore.inMemory()
    try store.seedIfNeeded()
    let before = store.siteCount

    #expect(throws: PackInstallError.self) {
      try PackInstaller().install(
        from: source,
        packID: "kuta",
        version: "1.0.0",
        jsonFileName: "kuta.json",
        into: packsRoot,
        content: store
      )
    }

    #expect(store.siteCount == before)
    #expect(!fm.fileExists(atPath: packsRoot.appending(path: "kuta").path))

    try? fm.removeItem(at: scratch)
  }

  @Test func successfulInstallSeedsAndCopiesAudio() throws {
    let fm = FileManager.default
    let scratch = fm.temporaryDirectory.appending(
      path: "cooltour-install-ok-\(UUID().uuidString)"
    )
    let source = scratch.appending(path: "source")
    let audioDir = source.appending(path: "audio")
    let packsRoot = scratch.appending(path: "Packs")
    try fm.createDirectory(at: audioDir, withIntermediateDirectories: true)
    try Data(validPackJSON.utf8).write(to: source.appending(path: "kuta.json"))
    try Data("fake-audio".utf8).write(to: audioDir.appending(path: "clip.m4a"))

    let store = LocalContentStore.inMemory()
    try store.seedIfNeeded()

    try PackInstaller().install(
      from: source,
      packID: "kuta",
      version: "1.0.0",
      jsonFileName: "kuta.json",
      into: packsRoot,
      content: store
    )

    #expect(store.allSites().contains { $0.slug == "install-kuta-site" })
    let copied = packsRoot.appending(path: "kuta/1.0.0/audio/clip.m4a")
    #expect(fm.fileExists(atPath: copied.path))

    try? fm.removeItem(at: scratch)
  }
}

private let validPackJSON = """
  {
    "contentPackVersion": "1.0.0",
    "region": "Kuta",
    "sites": [
      {
        "slug": "install-kuta-site",
        "name": "Install Kuta Site",
        "district": "Kuta",
        "lat": -8.737,
        "lng": 115.175,
        "triggerRadiusMeters": 40,
        "headingRequired": false,
        "stories": [
          {
            "slug": "install-kuta-site-01",
            "title": "Fixture",
            "audioFile": "clip.m4a",
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
