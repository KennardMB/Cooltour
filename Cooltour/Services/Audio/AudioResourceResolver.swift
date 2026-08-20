import Foundation

/// Local-only lookup for a story's audio file. Bundle first for Denpasar; Application Support
/// for a downloaded pack. Never returns an HTTP URL — missing file means silence.
enum AudioResourceResolver {
  nonisolated static func url(
    for audioAssetName: String,
    packID: String?,
    bundle: Bundle = .main,
    packsRoot: URL,
    fileManager: FileManager = .default
  ) -> URL? {
    let isBundled = packID == nil || packID == AppConfig.bundledPackID
    if isBundled {
      return bundle.url(forResource: audioAssetName, withExtension: nil)
    }

    guard let packID else { return nil }
    let packDir = packsRoot.appending(path: packID, directoryHint: .isDirectory)
    guard
      let versions = try? fileManager.contentsOfDirectory(
        at: packDir,
        includingPropertiesForKeys: [.isDirectoryKey],
        options: [.skipsHiddenFiles]
      )
    else { return nil }

    let versionDirs = versions.filter { url in
      (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
    }
    .sorted { $0.lastPathComponent > $1.lastPathComponent }

    for versionDir in versionDirs {
      let candidate = versionDir.appending(path: "audio").appending(path: audioAssetName)
      if fileManager.fileExists(atPath: candidate.path) {
        return candidate
      }
    }
    return nil
  }

  nonisolated static func defaultPacksRoot() -> URL {
    let support = FileManager.default.urls(
      for: .applicationSupportDirectory,
      in: .userDomainMask
    ).first
      ?? FileManager.default.temporaryDirectory
    return support.appending(path: "Packs", directoryHint: .isDirectory)
  }
}
