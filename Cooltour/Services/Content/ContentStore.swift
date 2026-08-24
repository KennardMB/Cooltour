import Foundation
import SwiftData

@MainActor
protocol ContentStore: AnyObject {
  var siteCount: Int { get }
  func allSites() -> [Site]
}

@MainActor
final class LocalContentStore: ContentStore {
  private let container: ModelContainer
  private let packNames: [String]
  private var context: ModelContext { container.mainContext }

  private static let seededVersionKey = "seededContentPackVersion"

  init(
    container: ModelContainer,
    packNames: [String] = AppConfig.contentPackNames
  ) {
    self.container = container
    self.packNames = packNames
    Task { @MainActor in
      _ = self.allSites()
    }
  }

  static func inMemory(packNames: [String] = AppConfig.contentPackNames)
    -> LocalContentStore
  {
    let container = try! ModelContainer(
      for: Site.self,
      Story.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let store = LocalContentStore(container: container, packNames: packNames)
    try? store.seedIfNeeded()
    return store
  }

  /// Re-seeds only when the bundled pack version changes, so relaunching never duplicates.
  func seedIfNeeded() throws {
    let packs = try packNames.map { try ContentPack.bundled(named: $0) }
    // One fingerprint across every pack, so adding/removing a pack or bumping any
    // version re-seeds. Names are included so reordering packs also counts as a change.
    let combinedVersion = zip(packNames, packs)
      .map { "\($0)@\($1.contentPackVersion)" }
      .joined(separator: ",")
    let seeded = UserDefaults.standard.string(forKey: Self.seededVersionKey)
    let existingCount = try context.fetchCount(FetchDescriptor<Site>())
    #if !DEBUG
    guard seeded != combinedVersion || existingCount == 0 else {
      return
    }
    #endif

    cachedSites = nil
    try context.delete(model: Site.self)

    for pack in packs {
      for siteData in pack.sites {
        let site = Site(
          slug: siteData.slug,
          name: siteData.name,
          districtName: siteData.district,
          latitude: siteData.lat,
          longitude: siteData.lng,
          triggerRadiusMeters: siteData.triggerRadiusMeters,
          headingRequired: siteData.headingRequired,
          thumbnailAssetName: siteData.imageFile
        )
        context.insert(site)

        for storyData in siteData.stories {
          let story = Story(
            slug: storyData.slug,
            title: storyData.title,
            audioAssetName: storyData.audioFile.en,
            audioAssetNameIndonesian: storyData.audioFile.id,
            transcript: storyData.transcript.en,
            transcriptIndonesian: storyData.transcript.id,
            durationSeconds: storyData.durationSeconds.en,
            durationSecondsIndonesian: storyData.durationSeconds.id,
            narratorNote: storyData.narratorNote,
            timeOfDayTag: storyData.timeOfDayTag
          )
          context.insert(story)
          story.site = site
        }
      }
    }

    try context.save()
    UserDefaults.standard.set(
      combinedVersion,
      forKey: Self.seededVersionKey
    )
  }

  private var cachedSites: [Site]?

  func allSites() -> [Site] {
    if let cached = cachedSites { return cached }
    let descriptor = FetchDescriptor<Site>(sortBy: [SortDescriptor(\.name)])
    let fetched = (try? context.fetch(descriptor)) ?? []
    cachedSites = fetched
    return fetched
  }

  var siteCount: Int {
    (try? context.fetchCount(FetchDescriptor<Site>())) ?? 0
  }
}
