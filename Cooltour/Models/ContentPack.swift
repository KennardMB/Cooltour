import Foundation

/// Decoded shape of the bundled JSON. Kept separate from the SwiftData models so the
/// same loader can serve a future downloaded pack.
struct ContentPack: Decodable {
  let contentPackVersion: String
  let region: String
  let sites: [SiteData]

  struct SiteData: Decodable {
    let slug: String
    let name: String
    let district: String
    let lat: Double
    let lng: Double
    let triggerRadiusMeters: Double
    let headingRequired: Bool
    let stories: [StoryData]
  }

  /// English + optional Indonesian string. Older packs may ship a plain string
  /// (treated as English only).
  struct LocalizedString: Decodable {
    let en: String
    let id: String?

    init(en: String, id: String? = nil) {
      self.en = en
      self.id = id
    }

    init(from decoder: Decoder) throws {
      if let single = try? decoder.singleValueContainer().decode(String.self) {
        self.en = single
        self.id = nil
        return
      }
      let object = try decoder.container(keyedBy: CodingKeys.self)
      self.en = try object.decode(String.self, forKey: .en)
      self.id = try object.decodeIfPresent(String.self, forKey: .id)
    }

    private enum CodingKeys: String, CodingKey {
      case en, id
    }
  }

  /// Per-language spoken length. Older packs may ship a single number (English).
  struct LocalizedDuration: Decodable {
    let en: Double
    let id: Double?

    init(en: Double, id: Double? = nil) {
      self.en = en
      self.id = id
    }

    init(from decoder: Decoder) throws {
      if let single = try? decoder.singleValueContainer().decode(Double.self) {
        self.en = single
        self.id = nil
        return
      }
      let object = try decoder.container(keyedBy: CodingKeys.self)
      self.en = try object.decode(Double.self, forKey: .en)
      self.id = try object.decodeIfPresent(Double.self, forKey: .id)
    }

    private enum CodingKeys: String, CodingKey {
      case en, id
    }
  }

  struct StoryData: Decodable {
    let slug: String
    let title: String
    let audioFile: LocalizedString
    let transcript: LocalizedString
    let durationSeconds: LocalizedDuration
    let narratorNote: String?
    let timeOfDayTag: String?
  }
}

extension ContentPack {
  enum LoadError: Error {
    case missingResource(String)
  }

  static func bundled(named name: String, in bundle: Bundle = .main) throws
    -> ContentPack
  {
    guard let url = bundle.url(forResource: name, withExtension: "json") else {
      throw LoadError.missingResource("\(name).json")
    }
    return try JSONDecoder().decode(
      ContentPack.self,
      from: Data(contentsOf: url)
    )
  }
}
