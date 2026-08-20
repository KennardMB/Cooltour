import Foundation
import Testing

@testable import Cooltour

struct PackCatalogTests {
  @Test func decodesCatalog() throws {
    let json = """
      {
        "catalogVersion": "1",
        "packs": [
          {
            "id": "kuta",
            "name": "Kuta",
            "version": "1.0.0",
            "sizeBytes": 2400000,
            "zipPath": "packs/kuta/1.0.0.zip",
            "latitude": -8.737,
            "longitude": 115.175,
            "radiusMeters": 8000
          }
        ]
      }
      """
    let catalog = try JSONDecoder().decode(PackCatalog.self, from: Data(json.utf8))
    #expect(catalog.catalogVersion == "1")
    #expect(catalog.packs.count == 1)
    #expect(catalog.packs[0].id == "kuta")
    #expect(catalog.packs[0].radiusMeters == 8000)
  }
}
