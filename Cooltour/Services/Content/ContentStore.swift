import Foundation

protocol ContentStore: AnyObject {
    var siteCount: Int { get }
}

@Observable
final class MockContentStore: ContentStore {
    var siteCount = 6
}
