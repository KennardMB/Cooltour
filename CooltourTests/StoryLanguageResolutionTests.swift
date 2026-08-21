import Foundation
import Testing

@Suite("Story language resolution")
struct StoryLanguageResolutionTests {
  @Test func indonesianAudioAssetNilWhenNotShipped() {
    let story = Story(
      slug: "test-01",
      title: "Test",
      audioAssetName: "test-01-en.m4a",
      transcript: "English text",
      durationSeconds: 40
    )
    #expect(story.audioAssetName(for: .english) == "test-01-en.m4a")
    #expect(story.audioAssetName(for: .indonesian) == nil)
  }

  @Test func indonesianFieldsResolveWhenPresent() {
    let story = Story(
      slug: "test-01",
      title: "Test",
      audioAssetName: "test-01-en.m4a",
      audioAssetNameIndonesian: "test-01-id.m4a",
      transcript: "English text",
      transcriptIndonesian: "Teks Indonesia",
      durationSeconds: 40,
      durationSecondsIndonesian: 42
    )
    #expect(story.audioAssetName(for: .indonesian) == "test-01-id.m4a")
    #expect(story.transcript(for: .indonesian) == "Teks Indonesia")
    #expect(story.durationSeconds(for: .indonesian) == 42)
  }
}
