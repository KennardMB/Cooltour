import Foundation
import Testing

@Suite("SettingsStore localization")
@MainActor
struct SettingsStoreLocalizationTests {
  @Test func appLanguagePersistsAcrossRelaunch() {
    let defaults = UserDefaults(suiteName: "test.cooltour.appLanguage.\(UUID().uuidString)")!
    defer { defaults.removePersistentDomain(forName: defaults.suiteName!) }

    let first = SettingsStore(defaults: defaults)
    first.appLanguage = .indonesian

    let second = SettingsStore(defaults: defaults)
    #expect(second.appLanguage == .indonesian)
    #expect(second.effectiveLocale.identifier.hasPrefix("id"))
  }

  @Test func audioLanguagePersistsAndDefaultsToEnglish() {
    let defaults = UserDefaults(suiteName: "test.cooltour.audioLanguage.\(UUID().uuidString)")!
    defer { defaults.removePersistentDomain(forName: defaults.suiteName!) }

    let fresh = SettingsStore(defaults: defaults)
    #expect(fresh.audioLanguage == .english)

    fresh.audioLanguage = .indonesian
    let reloaded = SettingsStore(defaults: defaults)
    #expect(reloaded.audioLanguage == .indonesian)
  }

  @Test func systemAppLanguageResolvesFromDeviceLocale() {
    let defaults = UserDefaults(suiteName: "test.cooltour.systemLang.\(UUID().uuidString)")!
    defer { defaults.removePersistentDomain(forName: defaults.suiteName!) }

    let store = SettingsStore(defaults: defaults)
    store.appLanguage = .system
    #expect(store.resolvedLanguageCode == "en" || store.resolvedLanguageCode == "id")
    #expect(store.effectiveLocale.identifier == store.resolvedLanguageCode)
  }

  @Test func indonesianAppLanguageResolvesToID() {
    let defaults = UserDefaults(suiteName: "test.cooltour.idLang.\(UUID().uuidString)")!
    defer { defaults.removePersistentDomain(forName: defaults.suiteName!) }

    let store = SettingsStore(defaults: defaults)
    store.appLanguage = .indonesian
    #expect(store.resolvedLanguageCode == "id")
    #expect(store.effectiveLocale.identifier == "id")
  }
}
