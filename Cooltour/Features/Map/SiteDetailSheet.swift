import SwiftUI

struct SiteDetailSheet: View {
  let site: Site
  @Environment(AppEnvironment.self) private var environment
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      List {
        Section {
          VStack(alignment: .leading, spacing: 8) {
            Text(site.name)
              .font(.title2.weight(.bold))
            Text(site.districtName)
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
          .padding(.vertical, 8)
        }

        Section("Stories") {
          if site.stories.isEmpty {
            Text("No stories available for this site.")
              .foregroundStyle(.secondary)
          } else {
            ForEach(site.stories) { story in
              HStack {
                VStack(alignment: .leading, spacing: 4) {
                  Text(story.title)
                    .font(.headline)
                  Text("\(Int(story.durationSeconds)) seconds")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                  environment.audio.play(story: story)
                } label: {
                  Image(systemName: "play.circle.fill")
                    .font(.title)
                    .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
              }
              .padding(.vertical, 4)
            }
          }
        }
      }
      .navigationTitle(site.name)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
    .presentationDetents([.medium, .large])
  }
}
