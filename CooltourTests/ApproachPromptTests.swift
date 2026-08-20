import Testing

@testable import Cooltour

struct ApproachPromptTests {
  @Test func omitsDirectionWhenNil() {
    let text = ApproachPrompt.text(
      siteName: "Pura Maospahit",
      directionPhrase: nil,
      languageCode: "en"
    )
    #expect(text == "You're approaching Pura Maospahit. Press play to hear it.")
  }

  @Test func omitsDirectionWhenEmpty() {
    let text = ApproachPrompt.text(
      siteName: "Pura Maospahit",
      directionPhrase: "",
      languageCode: "en"
    )
    #expect(text == "You're approaching Pura Maospahit. Press play to hear it.")
  }

  @Test func includesDirectionWhenPresent() {
    let text = ApproachPrompt.text(
      siteName: "Pura Maospahit",
      directionPhrase: "on your left",
      languageCode: "en"
    )
    #expect(
      text == "You're approaching Pura Maospahit, on your left. Press play to hear it."
    )
  }

  @Test func defaultsToNoDirection() {
    let text = ApproachPrompt.text(siteName: "Museum Bali", languageCode: "en")
    #expect(text == "You're approaching Museum Bali. Press play to hear it.")
  }

  @Test func usesIndonesianWhenLanguageCodeIsID() {
    let text = ApproachPrompt.text(
      siteName: "Pura Maospahit",
      directionPhrase: nil,
      languageCode: "id"
    )
    #expect(text == "Anda mendekati Pura Maospahit. Tekan putar untuk mendengarkannya.")
  }

  @Test func dismissActionUsesLewatiInIndonesian() {
    #expect(ConsentStrings.dismissAction(languageCode: "id") == "Lewati")
    #expect(ConsentStrings.dismissAction(languageCode: "en") == "Dismiss")
    #expect(ConsentStrings.dismissWithCountdown(8, languageCode: "id") == "Lewati (8)")
  }
}
