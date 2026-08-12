// Checks the Slice 4 trigger log: a background trigger is only observable if it survives the
// process that recorded it, so the round-trip is the thing that must not break.
//
//   swiftc Cooltour/Models/TriggerEvent.swift Cooltour/Services/Location/TriggerLog.swift \
//       Testing/check-trigger-log.swift -o /tmp/check-trigger-log && /tmp/check-trigger-log

import Foundation

@main
struct TriggerLogChecks {
    static func event(_ slug: String, secondsAgo: Double, background: Bool = false) -> TriggerEvent {
        TriggerEvent(
            date: Date(timeIntervalSince1970: 1_700_000_000 - secondsAgo),
            siteSlug: slug,
            siteName: slug.capitalized,
            storySlug: "\(slug)-01",
            storyTitle: "Story of \(slug)",
            distanceMeters: 12,
            horizontalAccuracyMeters: 8,
            wasBackground: background
        )
    }

    static func main() {
        let suiteName = "TriggerLogChecks"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        var log = TriggerLog(defaults: defaults)
        assert(log.events.isEmpty, "a fresh log starts empty")

        log.insert(event("pura-maospahit", secondsAgo: 60, background: true))
        log.insert(event("museum-bali", secondsAgo: 0))

        assert(log.events.map(\.siteSlug) == ["museum-bali", "pura-maospahit"], "newest first")

        // The one that matters: the app was killed and relaunched — a new log has to see the
        // background trigger that fired while nobody was looking.
        let reloaded = TriggerLog(defaults: defaults)
        assert(reloaded.events.count == 2, "log survives a new process")
        assert(reloaded.events[1].wasBackground, "the background marker survives too")
        assert(reloaded.events[1].siteSlug == "pura-maospahit")
        assert(reloaded.events[0].date == log.events[0].date, "dates round-trip exactly")
        assert(Set(reloaded.events.map(\.id)).count == 2, "ids stay distinct across a reload")

        // A long walk must not grow the log without bound.
        for index in 0..<TriggerLog.maxEntries * 2 {
            log.insert(event("site-\(index)", secondsAgo: -Double(index)))
        }
        assert(log.events.count == TriggerLog.maxEntries, "capped at maxEntries")
        assert(log.events.first?.siteSlug == "site-\(TriggerLog.maxEntries * 2 - 1)", "keeps the newest")
        assert(TriggerLog(defaults: defaults).events.count == TriggerLog.maxEntries, "cap persists")

        var cleared = TriggerLog(defaults: defaults)
        cleared.clear()
        assert(TriggerLog(defaults: defaults).events.isEmpty, "clear wipes the stored log")

        defaults.removePersistentDomain(forName: suiteName)
        print("check-trigger-log: all checks passed")
    }
}
