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

    struct StoryData: Decodable {
        let slug: String
        let title: String
        let audioFile: String
        let transcript: String
        let durationSeconds: Double
        let narratorNote: String?
        let timeOfDayTag: String?
    }
}

extension ContentPack {
    enum LoadError: Error {
        case missingResource(String)
    }

    static func bundled(named name: String, in bundle: Bundle = .main) throws -> ContentPack {
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw LoadError.missingResource("\(name).json")
        }
        return try JSONDecoder().decode(ContentPack.self, from: Data(contentsOf: url))
    }
}
