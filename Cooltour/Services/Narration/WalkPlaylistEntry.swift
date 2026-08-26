import Foundation

/// One entry in the walk's site carousel. Value type so Now can list it without holding SwiftData.
struct WalkPlaylistEntry: Identifiable, Equatable {
  let id: UUID
  let siteSlug: String
  let siteName: String
  let storySlug: String
  let storyTitle: String
  var hasStarted: Bool
}
