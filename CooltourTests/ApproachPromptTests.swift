import Testing

@testable import Cooltour

struct ApproachPromptTests {
  @Test func omitsDirectionWhenNil() {
    let text = ApproachPrompt.text(siteName: "Pura Maospahit", directionPhrase: nil)
    #expect(text == "You're approaching Pura Maospahit. Press play to hear it.")
  }

  @Test func omitsDirectionWhenEmpty() {
    let text = ApproachPrompt.text(siteName: "Pura Maospahit", directionPhrase: "")
    #expect(text == "You're approaching Pura Maospahit. Press play to hear it.")
  }

  @Test func includesDirectionWhenPresent() {
    let text = ApproachPrompt.text(siteName: "Pura Maospahit", directionPhrase: "on your left")
    #expect(text == "You're approaching Pura Maospahit, on your left. Press play to hear it.")
  }

  @Test func defaultsToNoDirection() {
    let text = ApproachPrompt.text(siteName: "Museum Bali")
    #expect(text == "You're approaching Museum Bali. Press play to hear it.")
  }
}
