import Foundation

enum PackInstallError: Error, Equatable {
  case missingJSON(String)
  case missingAudio(String)
  case copyFailed
}

/// Copies a pack directory into Application Support only after JSON + every audio file checks out.
struct PackInstaller {
  var fileManager: FileManager = .default

  func install(
    from sourceDirectory: URL,
    packID: String,
    version: String,
    jsonFileName: String,
    into packsRoot: URL,
    content: any ContentStore
  ) throws {
    let jsonURL = sourceDirectory.appending(path: jsonFileName)
    guard fileManager.fileExists(atPath: jsonURL.path) else {
      throw PackInstallError.missingJSON(jsonFileName)
    }
    let pack = try JSONDecoder().decode(
      ContentPack.self,
      from: Data(contentsOf: jsonURL)
    )

    let audioDir = sourceDirectory.appending(path: "audio")
    for site in pack.sites {
      for story in site.stories {
        let audio = audioDir.appending(path: story.audioFile)
        guard fileManager.fileExists(atPath: audio.path) else {
          throw PackInstallError.missingAudio(story.audioFile)
        }
      }
    }

    let destination = packsRoot
      .appending(path: packID, directoryHint: .isDirectory)
      .appending(path: version, directoryHint: .isDirectory)
    let tempParent = packsRoot.appending(path: ".tmp", directoryHint: .isDirectory)
    let temp = tempParent.appending(path: "\(packID)-\(UUID().uuidString)")

    do {
      try fileManager.createDirectory(at: temp, withIntermediateDirectories: true)
      try copyContents(of: sourceDirectory, to: temp)
      if fileManager.fileExists(atPath: destination.path) {
        try fileManager.removeItem(at: destination)
      }
      try fileManager.createDirectory(
        at: destination.deletingLastPathComponent(),
        withIntermediateDirectories: true
      )
      try fileManager.moveItem(at: temp, to: destination)
      try? fileManager.removeItem(at: tempParent)
    } catch {
      try? fileManager.removeItem(at: temp)
      try? fileManager.removeItem(at: tempParent)
      throw PackInstallError.copyFailed
    }

    do {
      try content.install(pack, packID: packID)
    } catch {
      try? fileManager.removeItem(at: destination)
      throw error
    }
  }

  private func copyContents(of source: URL, to destination: URL) throws {
    let items = try fileManager.contentsOfDirectory(
      at: source,
      includingPropertiesForKeys: nil
    )
    for item in items {
      try fileManager.copyItem(
        at: item,
        to: destination.appending(path: item.lastPathComponent)
      )
    }
  }
}
