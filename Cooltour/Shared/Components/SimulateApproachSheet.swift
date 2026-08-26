import SwiftUI

/// Reusable sheet for debug simulate-approach — picks a single site to trigger proximity
/// as if the user walked up to it.
struct SimulateApproachSheet: View {
  @Environment(\.dismiss) private var dismiss

  let siteGroups: [(district: String, sites: [Site])]
  let onSelectSite: (Site) -> Void

  @State private var isShowingScanner = false

  var body: some View {
    NavigationStack {
      List {
        // Exhibition QR Scanner Action
        Section {
          Button {
            isShowingScanner = true
          } label: {
            HStack(spacing: 12) {
              Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(
                  RoundedRectangle(cornerRadius: 10)
                    .fill(Color(red: 29 / 255, green: 82 / 255, blue: 216 / 255))
                )

              VStack(alignment: .leading, spacing: 2) {
                Text("Scan Site QR Code")
                  .font(.system(size: 16, weight: .semibold))
                  .foregroundStyle(AppColor.Text.primary)

                Text("Point camera at exhibition stand poster")
                  .font(.system(size: 13))
                  .foregroundStyle(Color(red: 104 / 255, green: 104 / 255, blue: 102 / 255))
              }

              Spacer()

              Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.secondary)
            }
            .padding(.vertical, 4)
          }
          .buttonStyle(.plain)
        } header: {
          Text("Exhibition Walk Simulation")
        }

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
    .sheet(isPresented: $isShowingScanner) {
      QRCodeScannerSheet { scannedCode in
        handleScannedCode(scannedCode)
      }
    }
  }

  private func handleScannedCode(_ code: String) {
    var targetSlug: String?
    if let url = URL(string: code), url.scheme?.lowercased() == "cooltour" {
      if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
        let slugItem = components.queryItems?.first(where: {
          $0.name == "slug" || $0.name == "site" || $0.name == "id"
        })?.value
      {
        targetSlug = slugItem
      } else {
        let pathComponents = url.pathComponents.filter { $0 != "/" && !$0.isEmpty }
        let host = url.host(percentEncoded: false) ?? url.host
        if let host, host != "site" && host != "approach" {
          targetSlug = host
        } else if let last = pathComponents.last {
          targetSlug = last
        }
      }
    } else {
      targetSlug = code.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    guard let slug = targetSlug else { return }
    let allSites = siteGroups.flatMap(\.sites)
    if let site = allSites.first(where: { $0.slug.caseInsensitiveCompare(slug) == .orderedSame }) {
      onSelectSite(site)
      dismiss()
    }
  }
}
