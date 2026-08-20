import Foundation

/// Builds an installable pack folder from flattened app-bundle resources.
/// Xcode copies `Resources/Packs/kuta/1.0.0/*` to the bundle root (no folder tree), so download
/// cannot open `Packs/kuta/1.0.0` as a directory — it has to reassemble from `kuta.json` + `.m4a`.
enum BundledPackSource {
  static func stage(
    packID: String,
    jsonURL: URL,
    audioURLs: [String: URL],
    fileManager: FileManager = .default
  ) throws -> URL {
    let pack = try JSONDecoder().decode(
      ContentPack.self,
      from: Data(contentsOf: jsonURL)
    )

    let temp = fileManager.temporaryDirectory
      .appending(path: "cooltour-stage-\(packID)-\(UUID().uuidString)")
    let audioDir = temp.appending(path: "audio", directoryHint: .isDirectory)
    try fileManager.createDirectory(at: audioDir, withIntermediateDirectories: true)
    try fileManager.copyItem(
      at: jsonURL,
      to: temp.appending(path: "\(packID).json")
    )

    for site in pack.sites {
      for story in site.stories {
        guard let audioURL = audioURLs[story.audioFile] else {
          throw PackInstallError.missingAudio(story.audioFile)
        }
        let dest = audioDir.appending(path: story.audioFile)
        if !fileManager.fileExists(atPath: dest.path) {
          try fileManager.copyItem(at: audioURL, to: dest)
        }
      }
    }
    return temp
  }

  static func audioURL(named fileName: String, in bundle: Bundle) -> URL? {
    if let url = bundle.url(forResource: fileName, withExtension: nil) {
      return url
    }
    let name = (fileName as NSString).deletingPathExtension
    let ext = (fileName as NSString).pathExtension
    guard !ext.isEmpty else { return nil }
    return bundle.url(forResource: name, withExtension: ext)
  }
}
