import Testing

@testable import Cooltour

/// Proves the Swift Testing target is wired to the app module and runs. Real coverage arrives with
/// the slices that need it (`ApproachPrompt` in Slice 11b/D, the coordinator in Slice 11b/E).
struct TestTargetSmokeTests {
  @Test func testTargetCanImportAppModule() {
    #expect(AppConfig.appName == "Walkaby")
  }
}
