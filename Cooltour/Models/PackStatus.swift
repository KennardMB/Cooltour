import Foundation

/// Install state for one catalog pack. `downloading` progress is 0...1.
enum PackStatus: Equatable {
  case notInstalled
  case downloading(progress: Double)
  case installed(version: String, sizeBytes: Int)
  case failed(message: String)
}
