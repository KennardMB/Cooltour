import Foundation
import Observation

/// Loads the bundled catalog and copies bundled pack folders through `PackInstaller`.
/// Same install path later serves an R2 zip — only the fetch changes.
@Observable
final class LocalContentPackLibrary: ContentPackLibrary {
  private(set) var catalog: PackCatalog?
  private(set) var lastCatalogError: String?
  private var statuses: [String: PackStatus] = [:]
  private var downloadTask: Task<Void, Never>?

  private let content: any ContentStore
  private let bundle: Bundle
  private let packsRoot: URL
  private let installer: PackInstaller
  private let fileManager: FileManager

  init(
    content: any ContentStore,
    bundle: Bundle = .main,
    packsRoot: URL = AudioResourceResolver.defaultPacksRoot(),
    fileManager: FileManager = .default
  ) {
    self.content = content
    self.bundle = bundle
    self.packsRoot = packsRoot
    self.fileManager = fileManager
    self.installer = PackInstaller(fileManager: fileManager)
    reseatInstalledStatuses()
  }

  func status(for packID: String) -> PackStatus {
    statuses[packID] ?? .notInstalled
  }

  func packsRootURL() -> URL { packsRoot }

  func refreshCatalog() async {
    lastCatalogError = nil
    guard
      let url = bundle.url(
        forResource: AppConfig.contentCatalogResourceName,
        withExtension: "json"
      )
    else {
      lastCatalogError = "Catalog is missing from the app."
      return
    }
    do {
      catalog = try JSONDecoder().decode(PackCatalog.self, from: Data(contentsOf: url))
      reseatInstalledStatuses()
      try reseedsInstalledPacksIfNeeded()
    } catch {
      lastCatalogError = "Can’t refresh packs."
    }
  }

  func download(_ packID: String) async {
    guard let pack = catalog?.packs.first(where: { $0.id == packID }) else {
      statuses[packID] = .failed(message: "Unknown pack.")
      return
    }
    statuses[packID] = .downloading(progress: 0)

    // Stand-in until R2: Xcode flattens Packs/{id}/{version}/ into the bundle root, so we
    // reassemble a temp folder from {id}.json + each story's .m4a, then install as usual.
    guard
      let jsonURL = bundle.url(forResource: pack.id, withExtension: "json")
        ?? bundle.url(
          forResource: pack.id,
          withExtension: "json",
          subdirectory: pack.zipPath
        )
    else {
      statuses[packID] = .failed(message: "Pack files are missing from the app.")
      return
    }

    do {
      let decoded = try JSONDecoder().decode(
        ContentPack.self,
        from: Data(contentsOf: jsonURL)
      )
      var audioURLs: [String: URL] = [:]
      for site in decoded.sites {
        for story in site.stories {
          if audioURLs[story.audioFile] != nil { continue }
          guard
            let url = BundledPackSource.audioURL(named: story.audioFile, in: bundle)
          else {
            throw PackInstallError.missingAudio(story.audioFile)
          }
          audioURLs[story.audioFile] = url
        }
      }

      let staged = try BundledPackSource.stage(
        packID: pack.id,
        jsonURL: jsonURL,
        audioURLs: audioURLs,
        fileManager: fileManager
      )
      defer { try? fileManager.removeItem(at: staged) }

      try installer.install(
        from: staged,
        packID: pack.id,
        version: pack.version,
        jsonFileName: "\(pack.id).json",
        into: packsRoot,
        content: content
      )
      statuses[packID] = .installed(version: pack.version, sizeBytes: pack.sizeBytes)
    } catch {
      statuses[packID] = .failed(message: "Download failed. Try again.")
    }
  }

  func cancel(_ packID: String) {
    downloadTask?.cancel()
    if case .downloading = statuses[packID] {
      statuses[packID] = .notInstalled
    }
  }

  func delete(_ packID: String) async {
    try? content.uninstall(packID: packID)
    let packDir = packsRoot.appending(path: packID)
    try? fileManager.removeItem(at: packDir)
    statuses[packID] = .notInstalled
  }

  private func reseatInstalledStatuses() {
    guard let catalog else { return }
    for pack in catalog.packs {
      let destination = packsRoot
        .appending(path: pack.id)
        .appending(path: pack.version)
      if fileManager.fileExists(atPath: destination.path) {
        statuses[pack.id] = .installed(version: pack.version, sizeBytes: pack.sizeBytes)
      } else if statuses[pack.id] == nil {
        statuses[pack.id] = .notInstalled
      }
    }
  }

  /// Schema wipes drop SwiftData rows but leave files on disk — put the rows back.
  private func reseedsInstalledPacksIfNeeded() throws {
    guard let catalog else { return }
    for pack in catalog.packs {
      guard case .installed = statuses[pack.id] else { continue }
      let alreadySeeded = content.allSites().contains { $0.packID == pack.id }
      guard !alreadySeeded else { continue }
      let json = packsRoot
        .appending(path: pack.id)
        .appending(path: pack.version)
        .appending(path: "\(pack.id).json")
      guard fileManager.fileExists(atPath: json.path) else { continue }
      let decoded = try JSONDecoder().decode(
        ContentPack.self,
        from: Data(contentsOf: json)
      )
      try content.install(decoded, packID: pack.id)
    }
  }
}
