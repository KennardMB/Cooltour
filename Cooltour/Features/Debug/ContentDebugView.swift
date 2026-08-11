import SwiftData
import SwiftUI

/// Temporary Slice 1 acceptance surface: proves the pack round-tripped into SwiftData.
/// Delete once the Now and Map tabs render real content.
struct ContentDebugView: View {
    @Query(sort: \Site.name) private var sites: [Site]

    var body: some View {
        List {
            ForEach(sites) { site in
                Section(site.name) {
                    LabeledContent("District", value: site.districtName)
                    LabeledContent("Coordinate", value: "\(site.latitude), \(site.longitude)")
                    LabeledContent("Trigger radius", value: "\(Int(site.triggerRadiusMeters)) m")

                    ForEach(site.stories) { story in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(story.title).font(.headline)
                            Text("\(story.audioAssetName) · \(Int(story.durationSeconds))s")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(story.transcript)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .lineLimit(3)
                        }
                    }
                }
            }
        }
        .navigationTitle("\(sites.count) sites")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ContentDebugView()
    }
    .modelContainer(for: [Site.self, Story.self], inMemory: true)
}
