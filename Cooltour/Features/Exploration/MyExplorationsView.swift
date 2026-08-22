import SwiftData
import SwiftUI

// MARK: - My Explorations Screen (Figma Node 202:1287)

struct MyExplorationsView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(AppEnvironment.self) private var env
  @Query(sort: \Walk.startedAt, order: .reverse) private var walks: [Walk]
  
  init() {}
  
  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 0) {
        // Top Navigation Bar
        HStack {
          Button {
            dismiss()
          } label: {
            AppIcon(.chevronLeft, size: 24)
              .padding(AppSpacing.sm)
              .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .accessibilityLabel("Back")
          
          Spacer()
          
          Text("My explorations")
            .appFont(.heading3, color: AppColor.Text.primary)
          
          Spacer()
          
          // Balance spacing
          Color.clear
            .frame(width: 32, height: 32)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.sm)
        
        // Exploration Walk Cards List
        ScrollView {
          VStack(spacing: 20) {
            if walks.isEmpty {
              // Authentic Empty State
              VStack(spacing: AppSpacing.md) {
                Image(systemName: "figure.walk.circle")
                  .font(.system(size: 56, weight: .light))
                  .foregroundStyle(AppColor.Text.secondary)
                
                Text("No explorations yet")
                  .appFont(.heading3, color: AppColor.Text.primary)
                
                Text("Your triggered cultural sites and walking stories will appear here as you explore.")
                  .appFont(.captionL, color: AppColor.Text.secondary)
                  .multilineTextAlignment(.center)
                  .padding(.horizontal, 32)
              }
              .padding(.top, 80)
            } else {
              ForEach(Array(walks.enumerated()), id: \.element.id) { index, walk in
                let events = walk.triggerEvents.sorted { $0.firedAt > $1.firedAt }
                let title = walkTitle(for: walk, events: events)
                let timeText = walk.startedAt.formatted(date: .omitted, time: .shortened)
                let dateText = walk.startedAt.formatted(date: .numeric, time: .omitted)
                let theme = BinderCardTheme.forIndex(index)
                
                NavigationLink {
                  MyExplorationDetailsView(walk: walk)
                } label: {
                  ExplorationBinderCard(
                    title: title,
                    timeText: timeText,
                    dateText: dateText,
                    theme: theme
                  )
                }
                .buttonStyle(.plain)
              }
            }
          }
          .padding(.horizontal, AppSpacing.lg)
          .padding(.top, AppSpacing.lg)
          .padding(.bottom, 40)
        }
      }
      .defaultTiledBackground(scale: 0.20)
    }
  }
  
  private func walkTitle(for walk: Walk, events: [TriggerEvent]) -> String {
    if events.isEmpty {
      return "Walk on \(walk.startedAt.formatted(date: .abbreviated, time: .omitted))"
    }
    let siteNames = events.map(\.siteName)
    let uniqueSites = Array(NSOrderedSet(array: siteNames)).compactMap { $0 as? String }
    return uniqueSites.joined(separator: " · ")
  }
}

// MARK: - Exploration Detail Sheet (Triggered Sites Replay)

struct ExplorationDetailSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(AppEnvironment.self) private var env
  let walk: Walk
  
  init(walk: Walk) {
    self.walk = walk
  }
  
  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 0) {
        // Sheet Header
        HStack {
          VStack(alignment: .leading, spacing: 2) {
            Text("Exploration Sites")
              .appFont(.heading2, color: AppColor.Text.primary)
            
            Text("\(walk.startedAt.formatted(date: .abbreviated, time: .shortened))")
              .appFont(.label, color: AppColor.Text.secondary)
          }
          
          Spacer()
          
          Button {
            dismiss()
          } label: {
            AppIcon(.close, size: 28)
          }
          .buttonStyle(.plain)
          .accessibilityLabel("Close")
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.lg)
        .padding(.bottom, AppSpacing.md)
        
        let events = walk.triggerEvents.sorted { $0.firedAt > $1.firedAt }
        
        if events.isEmpty {
          VStack(spacing: AppSpacing.sm) {
            Spacer()
            Text("No stories triggered during this walk.")
              .appFont(.captionL, color: AppColor.Text.secondary)
            Spacer()
          }
          .frame(maxWidth: .infinity)
        } else {
          List {
            ForEach(events) { event in
              Button {
                // Tap to replay story
                if let site = env.content.allSites().first(where: { $0.slug == event.siteSlug }),
                   let story = site.stories.first(where: { $0.slug == event.storySlug }) {
                  env.audio.play(story: story)
                  dismiss()
                }
              } label: {
                TriggerEventRow(event: event)
              }
              .listRowBackground(AppColor.Background.pure)
            }
          }
          .listStyle(.plain)
          .scrollContentBackground(.hidden)
        }
      }
      .background(AppColor.Background.canvas)
    }
  }
}

// MARK: - Previews

#Preview("My Explorations Screen") {
  MyExplorationsView()
    .environment(AppEnvironment())
}
