import Foundation

/// Pure trigger decision core: distances in, "these sites just fired" out.
///
/// Deliberately free of Core Location and SwiftData so the nasty cases — boundary flapping,
/// re-entry, and low-accuracy fixes — can be tested without GPS or a database.
struct ProximityEvaluator {
    struct Candidate: Equatable {
        let slug: String
        let distanceMeters: Double
        let triggerRadiusMeters: Double
    }

    /// Sites the user is currently inside. They stay disarmed until the user leaves the
    /// re-arm ring, which is what stops a jittery fix at the boundary from re-firing.
    private(set) var insideSlugs: Set<String> = []

    private let maxAccuracyMeters: Double
    private let reArmMultiplier: Double

    init(
        maxAccuracyMeters: Double = AppConfig.maxLocationAccuracyMeters,
        reArmMultiplier: Double = AppConfig.reArmRadiusMultiplier
    ) {
        self.maxAccuracyMeters = maxAccuracyMeters
        self.reArmMultiplier = reArmMultiplier
    }

    /// A negative accuracy means Core Location couldn't produce a valid fix at all.
    func accepts(horizontalAccuracyMeters: Double) -> Bool {
        horizontalAccuracyMeters > 0 && horizontalAccuracyMeters <= maxAccuracyMeters
    }

    func isArmed(_ slug: String) -> Bool { !insideSlugs.contains(slug) }

    /// - Returns: slugs that entered their radius on this fix, nearest first. Empty when the
    ///   fix is too vague to name a place — a wrong story costs more trust than silence does.
    mutating func evaluate(
        candidates: [Candidate],
        horizontalAccuracyMeters: Double
    ) -> [String] {
        // An untrusted fix must not re-arm anything either, or a bad reading mid-visit
        // would let the same story fire twice.
        guard accepts(horizontalAccuracyMeters: horizontalAccuracyMeters) else { return [] }

        var fired: [String] = []
        for candidate in candidates.sorted(by: { $0.distanceMeters < $1.distanceMeters }) {
            if candidate.distanceMeters <= candidate.triggerRadiusMeters {
                if insideSlugs.insert(candidate.slug).inserted {
                    fired.append(candidate.slug)
                }
            } else if candidate.distanceMeters > candidate.triggerRadiusMeters * reArmMultiplier {
                insideSlugs.remove(candidate.slug)
            }
        }
        return fired
    }
}
