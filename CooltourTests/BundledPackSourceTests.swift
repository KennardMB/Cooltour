import Foundation
import Testing

@testable import Cooltour

struct BundledPackSourceTests {
  @Test func stagesJSONAndAudioIntoInstallableFolder() throws {
    let fm = FileManager.default
    let scratch = fm.temporaryDirectory.appending(
      path: "cooltour-stage-\(UUID().uuidString)"
    )
    try fm.createDirectory(at: scratch, withIntermediateDirectories: true)
    let json = scratch.appending(path: "kuta.json")
    let audio = scratch.appending(path: "clip.m4a")
    try Data(stageJSON.utf8).write(to: json)
    try Data("fake".utf8).write(to: audio)

    let staged = try BundledPackSource.stage(
      packID: "kuta",
      jsonURL: json,
      audioURLs: ["clip.m4a": audio],
      fileManager: fm
    )
    defer { try? fm.removeItem(at: staged) }

    #expect(fm.fileExists(atPath: staged.appending(path: "kuta.json").path))
    #expect(fm.fileExists(atPath: staged.appending(path: "audio/clip.m4a").path))

    try? fm.removeItem(at: scratch)
  }

  @Test func missingAudioThrows() throws {
    let fm = FileManager.default
    let scratch = fm.temporaryDirectory.appending(
      path: "cooltour-stage-miss-\(UUID().uuidString)"
    )
    try fm.createDirectory(at: scratch, withIntermediateDirectories: true)
    let json = scratch.appending(path: "kuta.json")
    try Data(stageJSON.utf8).write(to: json)

    #expect(throws: PackInstallError.missingAudio("clip.m4a")) {
      try BundledPackSource.stage(
        packID: "kuta",
        jsonURL: json,
        audioURLs: [:],
        fileManager: fm
      )
    }

    try? fm.removeItem(at: scratch)
  }
}

private let stageJSON = """
  {
    "contentPackVersion": "1.0.0",
    "region": "Kuta",
    "sites": [
      {
        "slug": "stage-site",
        "name": "Stage",
        "district": "Kuta",
        "lat": -8.7,
        "lng": 115.1,
        "triggerRadiusMeters": 40,
        "headingRequired": false,
        "stories": [
          {
            "slug": "stage-01",
            "title": "Stage",
            "audioFile": "clip.m4a",
            "transcript": "…",
            "durationSeconds": 1,
            "narratorNote": null,
            "timeOfDayTag": null
          }
        ]
      }
    ]
  }
  """
