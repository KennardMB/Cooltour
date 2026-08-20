import Foundation

@MainActor
protocol ContentPackLibrary: AnyObject {
  var catalog: PackCatalog? { get }
  var lastCatalogError: String? { get }
  func status(for packID: String) -> PackStatus
  func refreshCatalog() async
  func download(_ packID: String) async
  func cancel(_ packID: String)
  func delete(_ packID: String) async
  func packsRootURL() -> URL
}
