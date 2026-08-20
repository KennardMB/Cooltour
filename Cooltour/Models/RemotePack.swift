import Foundation

/// One downloadable city pack from the public catalog.
nonisolated struct RemotePack: Decodable, Identifiable, Equatable, Sendable {
  let id: String
  let name: String
  let version: String
  let sizeBytes: Int
  let zipPath: String
  let latitude: Double
  let longitude: Double
  let radiusMeters: Double
}
