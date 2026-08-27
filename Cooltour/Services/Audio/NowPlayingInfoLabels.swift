import Foundation

/// Lock-screen / Control Center Now Playing copy. Place-first: the site is the "track",
/// the district is the "artist". Story titles stay in-app (transcript, Now card).
enum NowPlayingInfoLabels {
  static func title(for story: Story) -> String {
    let siteName = story.site?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return siteName.isEmpty ? story.title : siteName
  }

  static func artist(for story: Story) -> String {
    let district = story.site?.districtName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return district.isEmpty ? AppConfig.appName : district
  }
}
