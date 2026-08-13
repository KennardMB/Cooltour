import Foundation

/// Trigger history that outlives the process.
///
/// A background trigger fires while the app is backgrounded — or after Core Location relaunched
/// it — so an in-memory array is gone before anyone can read it. Persisting the log is what makes
/// Slice 4 testable at all without notifications.
///
/// ponytail: UserDefaults JSON capped at `maxEntries`. Slice 8 promotes walk history to SwiftData;
/// move it there when history needs querying, not just reading back.
struct TriggerLog {
    static let defaultsKey = "recentTriggerEvents"
    static let maxEntries = 50

    private(set) var events: [TriggerEvent]
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let data = defaults.data(forKey: Self.defaultsKey)
        events = data.flatMap { try? JSONDecoder().decode([TriggerEvent].self, from: $0) } ?? []
    }

    /// Newest first, matching how the debug and history screens read it.
    mutating func insert(_ event: TriggerEvent) {
        events.insert(event, at: 0)
        events = Array(events.prefix(Self.maxEntries))
        save()
    }

    mutating func clear() {
        events = []
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(events) else { return }
        defaults.set(data, forKey: Self.defaultsKey)
    }
}
