import Foundation
import Testing

@testable import Cooltour

struct AudioResourceResolverTests {
  @Test func findsPackAudioInVersionFolder() throws {
    let root = FileManager.default.temporaryDirectory
      .appending(path: "cooltour-resolver-\(UUID().uuidString)")
    let audioDir = root.appending(path: "kuta/1.0.0/audio")
    try FileManager.default.createDirectory(at: audioDir, withIntermediateDirectories: true)
    let file = audioDir.appending(path: "clip.m4a")
    try Data("fake".utf8).write(to: file)

    let url = AudioResourceResolver.url(
      for: "clip.m4a",
      packID: "kuta",
      packsRoot: root
    )
    #expect(url == file)

    try? FileManager.default.removeItem(at: root)
  }

  @Test func missingPackAudioReturnsNil() {
    let root = FileManager.default.temporaryDirectory
      .appending(path: "cooltour-resolver-missing-\(UUID().uuidString)")
    let url = AudioResourceResolver.url(
      for: "nope.m4a",
      packID: "kuta",
      packsRoot: root
    )
    #expect(url == nil)
  }

  @Test func bundledPackLooksInTheAppBundle() {
    let url = AudioResourceResolver.url(
      for: "pura-maospahit-01.m4a",
      packID: AppConfig.bundledPackID,
      packsRoot: URL(fileURLWithPath: "/tmp")
    )
    #expect(url != nil)
  }

  @Test func neverReturnsHTTP() throws {
    let root = FileManager.default.temporaryDirectory
      .appending(path: "cooltour-resolver-http-\(UUID().uuidString)")
    let url = AudioResourceResolver.url(
      for: "clip.m4a",
      packID: "kuta",
      packsRoot: root
    )
    #expect(url?.scheme != "http")
    #expect(url?.scheme != "https")
  }
}
