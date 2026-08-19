import SwiftUI

/// The home tab. Reactive and in-the-moment — status line, the active/last story, quick
/// controls, and this session's trigger feed. No direct service access from here: everything
/// goes through `NowViewModel`.
struct NowView: View {
  @Environment(AppEnvironment.self) private var env
  @State private var viewModel: NowViewModel?

  var body: some View {
    NavigationStack {
      ScrollView {
        if let viewModel {
          content(viewModel)
            .padding()
        }
      }
      .navigationTitle("Now")
    }
    .task {
      if viewModel == nil {
        viewModel = NowViewModel(environment: env)
      }
    }
  }

  @ViewBuilder
  private func content(_ viewModel: NowViewModel) -> some View {
    @Bindable var settings = viewModel.settings

    VStack(alignment: .leading, spacing: 24) {
      Text(viewModel.statusText)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .accessibilityLabel(viewModel.statusText)

      if let story = viewModel.displayedStory, let site = story.site {
        NowCard(
          siteName: site.name,
          distanceMeters: viewModel.displayedDistanceMeters,
          storyTitle: story.title,
          snippet: viewModel.snippet(for: story),
          transcript: story.transcript,
          isPlaying: viewModel.isPlaying,
          isLoading: viewModel.isLoading,
          progress: viewModel.progress,
          durationSeconds: story.durationSeconds,
          speed: settings.defaultPlaybackSpeed,
          onTogglePlayback: viewModel.togglePlayback,
          onSelectSpeed: viewModel.selectSpeed
        )
        .id(story.slug)
      } else if let nearest = viewModel.nearestSite {
        teaser(nearest, viewModel: viewModel)
      } else {
        ContentUnavailableView(
          "Nothing nearby yet",
          systemImage: "location.slash",
          description: Text("Walk near a seeded site to hear its story.")
        )
      }

      // Speed lives on the Now card, next to the transport controls it actually affects —
      // a second copy here just duplicated it with no added function (user-reported: "speed
      // chips double"). Auto-play has no such home, so it stays as the one quick control.
      Toggle("Auto-play nearby stories", isOn: $settings.autoPlay)

      todaysWalkFeed(viewModel)
    }
  }

  private func teaser(_ nearest: NearbySite, viewModel: NowViewModel) -> some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text("Coming up")
          .font(.caption)
          .foregroundStyle(.secondary)
        Text("\(nearest.name) — \(Int(nearest.distanceMeters))m")
          .font(.subheadline.weight(.medium))
      }
      Spacer()
      Button("Play") { viewModel.playNearestSite() }
        .buttonStyle(.bordered)
    }
    .padding()
    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
  }

  private func todaysWalkFeed(_ viewModel: NowViewModel) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Today's walk")
        .font(.headline)

      if viewModel.todaysEvents.isEmpty {
        Text("Nothing triggered yet.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      } else {
        ForEach(viewModel.todaysEvents) { event in
          Button {
            viewModel.replay(event)
          } label: {
            VStack(alignment: .leading, spacing: 2) {
              Text(event.storyTitle)
                .font(.subheadline.weight(.medium))
              Text(event.siteName)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)

          if event.id != viewModel.todaysEvents.last?.id {
            Divider()
          }
        }
      }
    }
  }
}

#Preview {
  NowView().environment(AppEnvironment())
}
