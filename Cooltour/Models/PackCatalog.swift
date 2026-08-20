import Foundation

/// Public list of downloadable city packs. Fetched from R2 (or the bundled stand-in).
nonisolated struct PackCatalog: Decodable, Equatable, Sendable {
  let catalogVersion: String
  let packs: [RemotePack]
}
