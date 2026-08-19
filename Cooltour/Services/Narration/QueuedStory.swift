import Foundation

/// One entry in the walk's story queue. Value type so Now can list it without holding SwiftData.
nonisolated struct QueuedStory: Identifiable, Equatable, Sendable {
  let id: UUID
  let siteSlug: String
  let siteName: String
  let storySlug: String
  let storyTitle: String
}
