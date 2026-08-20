import Foundation
import Observation

@Observable
final class MockContentPackLibrary: ContentPackLibrary {
  var catalog: PackCatalog? = PackCatalog(
    catalogVersion: "1",
    packs: [
      RemotePack(
        id: "kuta",
        name: "Kuta",
        version: "1.0.0",
        sizeBytes: 434_000,
        zipPath: "Packs/kuta/1.0.0",
        latitude: -8.737,
        longitude: 115.175,
        radiusMeters: 8000
      )
    ]
  )
  var lastCatalogError: String?
  var statuses: [String: PackStatus] = [:]
  var downloadCalls: [String] = []
  var deleteCalls: [String] = []

  func status(for packID: String) -> PackStatus {
    statuses[packID] ?? .notInstalled
  }

  func refreshCatalog() async {}

  func download(_ packID: String) async {
    downloadCalls.append(packID)
    statuses[packID] = .installed(version: "1.0.0", sizeBytes: 1)
  }

  func cancel(_ packID: String) {}

  func delete(_ packID: String) async {
    deleteCalls.append(packID)
    statuses[packID] = .notInstalled
  }

  func packsRootURL() -> URL {
    FileManager.default.temporaryDirectory.appending(path: "MockPacks")
  }
}
