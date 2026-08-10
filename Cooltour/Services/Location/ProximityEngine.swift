import Foundation

protocol ProximityEngine: AnyObject {
    var isListening: Bool { get }
    func start()
    func stop()
}

@Observable
final class MockProximityEngine: ProximityEngine {
    private(set) var isListening = false

    func start() { isListening = true }
    func stop() { isListening = false }
}
