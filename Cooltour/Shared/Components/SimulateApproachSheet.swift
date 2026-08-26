import SwiftUI

/// Reusable sheet for debug simulate-approach — picks a single site to trigger proximity
/// as if the user walked up to it.
struct SimulateApproachSheet: View {
  @Environment(\.dismiss) private var dismiss

  let siteGroups: [(district: String, sites: [Site])]
  let onSelectSite: (Site) -> Void

  var body: some View {
    NavigationStack {
      List {
        ForEach(siteGroups, id: \.district) { group in
          Section(group.district) {
            ForEach(group.sites, id: \.slug) { site in
              Button {
                onSelectSite(site)
                dismiss()
              } label: {
                VStack(alignment: .leading, spacing: 3) {
                  Text(site.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppColor.Text.primary)

                  if let storyTitle = site.stories.first?.title {
                    Text(storyTitle)
                      .font(.system(size: 13, weight: .regular))
                      .foregroundStyle(Color(red: 104 / 255, green: 104 / 255, blue: 102 / 255))
                      .lineLimit(1)
                  }
                }
                .padding(.vertical, 2)
              }
              .buttonStyle(.plain)
            }
          }
        }
      }
      .navigationTitle("Simulate site approach")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Close") {
            dismiss()
          }
        }
      }
    }
    .presentationDetents([.medium, .large])
  }
}
