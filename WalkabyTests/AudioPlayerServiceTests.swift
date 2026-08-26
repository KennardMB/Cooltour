import Testing

@testable import Walkaby

@MainActor
struct AudioPlayerServiceTests {

  private func makeStory(slug: String = "pura-maospahit-01") -> Story {
    Story(
      slug: slug,
      title: "The Split Gate",
      audioAssetName: "\(slug).m4a",
      transcript: "…",
      durationSeconds: 42
    )
  }

  @Test func playSameStoryAfterPausePreservesProgress() {
    let audio = MockAudioPlayerService()
    let story = makeStory()

    audio.play(story: story)
    audio.seek(toProgress: 0.5)
    audio.pause()

    audio.play(story: story)

    #expect(audio.progress == 0.5)
    #expect(audio.isPlaying)
  }

  @Test func playDifferentStoryResetsProgress() {
    let audio = MockAudioPlayerService()
    let firstStory = makeStory(slug: "pura-maospahit-01")
    let secondStory = makeStory(slug: "pura-jagatnatha-01")

    audio.play(story: firstStory)
    audio.seek(toProgress: 0.5)
    audio.play(story: secondStory)

    #expect(audio.currentStory?.slug == secondStory.slug)
    #expect(audio.progress == 0.0)
  }
}
