import Foundation
import SwiftData

@MainActor
protocol ContentStore: AnyObject {
  var siteCount: Int { get }
  func allSites() -> [Site]
  func install(_ pack: ContentPack, packID: String) throws
  func uninstall(packID: String) throws
}

@MainActor
final class LocalContentStore: ContentStore {
  private let container: ModelContainer
  private let packName: String
  private var context: ModelContext { container.mainContext }

  private static let seededVersionKey = "seededContentPackVersion"

  init(container: ModelContainer, packName: String = AppConfig.contentPackName)
  {
    self.container = container
    self.packName = packName
    Task { @MainActor in
      _ = self.allSites()
    }
  }

  static func inMemory(packName: String = AppConfig.contentPackName)
    -> LocalContentStore
  {
    let container = try! ModelContainer(
      for: Site.self,
      Story.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let store = LocalContentStore(container: container, packName: packName)
    try? store.seedIfNeeded()
    return store
  }

  /// Re-seeds only when the bundled pack version changes, so relaunching never duplicates.
  func seedIfNeeded() throws {
    let pack = try ContentPack.bundled(named: packName)
    let seeded = UserDefaults.standard.string(forKey: Self.seededVersionKey)
    let existingCount = try context.fetchCount(FetchDescriptor<Site>())
    #if !DEBUG
    guard seeded != pack.contentPackVersion || existingCount == 0 else {
      return
    }
    #endif

    try replaceSites(in: pack, packID: AppConfig.bundledPackID)
    UserDefaults.standard.set(
      pack.contentPackVersion,
      forKey: Self.seededVersionKey
    )
  }

  func install(_ pack: ContentPack, packID: String) throws {
    try replaceSites(in: pack, packID: packID)
  }

  func uninstall(packID: String) throws {
    try deleteSites(packID: packID)
    try context.save()
    cachedSites = nil
  }

  /// Deletes only this pack's rows, then inserts the pack. Never `delete(model: Site.self)`.
  private func replaceSites(in pack: ContentPack, packID: String) throws {
    try deleteSites(packID: packID)

    for siteData in pack.sites {
      let site = Site(
        slug: siteData.slug,
        name: siteData.name,
        districtName: siteData.district,
        latitude: siteData.lat,
        longitude: siteData.lng,
        triggerRadiusMeters: siteData.triggerRadiusMeters,
        headingRequired: siteData.headingRequired,
        packID: packID
      )
      context.insert(site)

      for storyData in siteData.stories {
        let story = Story(
          slug: storyData.slug,
          title: storyData.title,
          audioAssetName: storyData.audioFile,
          transcript: storyData.transcript,
          durationSeconds: storyData.durationSeconds,
          narratorNote: storyData.narratorNote,
          timeOfDayTag: storyData.timeOfDayTag
        )
        context.insert(story)
        story.site = site
      }
    }

    try context.save()
    cachedSites = nil
  }

  private func deleteSites(packID: String) throws {
    let target = packID
    let descriptor = FetchDescriptor<Site>(
      predicate: #Predicate<Site> { $0.packID == target }
    )
    for site in try context.fetch(descriptor) {
      context.delete(site)
    }
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
