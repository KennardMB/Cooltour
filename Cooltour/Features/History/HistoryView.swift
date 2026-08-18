import SwiftData
import SwiftUI

struct HistoryView: View {
  @Environment(AppEnvironment.self) private var env
  @Query(sort: \Walk.startedAt, order: .reverse) private var walks: [Walk]
  
  var body: some View {
    NavigationStack {
      if walks.isEmpty {
        ContentUnavailableView(
          "History",
          systemImage: "clock",
          description: Text("Past walks appear here in slice 8.")
        )
      } else {
        List {
          ForEach(walks) { walk in
            Section(header: Text(walk.startedAt.formatted(date: .abbreviated, time: .shortened))) {
              let events = walk.triggerEvents.sorted { $0.firedAt > $1.firedAt }
              if events.isEmpty {
                Text("No stories triggered")
                  .foregroundStyle(.secondary)
                  .font(.callout)
              } else {
                ForEach(events) { event in
                  Button {
                    // Tap to replay story
                    if let site = env.content.allSites().first(where: { $0.slug == event.siteSlug }),
                       let story = site.stories.first(where: { $0.slug == event.storySlug }) {
                      env.audio.play(story: story)
                    }
                  } label: {
                    TriggerEventRow(event: event)
                  }
                  .buttonStyle(.plain)
                }
              }
            }
          }
        }
      }
    }
    .navigationTitle("History")
  }
}

#Preview {
  HistoryView()
}
