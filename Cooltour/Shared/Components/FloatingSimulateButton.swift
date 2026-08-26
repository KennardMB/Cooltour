import SwiftUI

/// Floating debug button for simulating proximity site triggers, placed in the bottom-right corner.
public struct FloatingSimulateButton: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var isShowingSheet: Bool = false

    public var bottomPadding: CGFloat

    public init(bottomPadding: CGFloat = 68) {
        self.bottomPadding = bottomPadding
    }

    private var simulatableSitesByDistrict: [(district: String, sites: [Site])] {
        Dictionary(grouping: environment.content.allSites(), by: \.districtName)
            .map { (district: $0.key, sites: $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.district < $1.district }
    }

    public var body: some View {
        Button {
            isShowingSheet = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(Color(red: 29 / 255, green: 82 / 255, blue: 216 / 255)) // #1D52D8
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.black.opacity(0.28), radius: 6, x: 0, y: 3)

                Image(systemName: "building.columns.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.white)
                    .frame(width: 56, height: 56)

                // Small "+" indicator badge above the museum icon
                Circle()
                    .fill(Color(red: 255 / 255, green: 102 / 255, blue: 52 / 255)) // #FF6634
                    .frame(width: 20, height: 20)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.white)
                    )
                    .offset(x: 2, y: -2)
            }
        }
        .buttonStyle(.plain)
        .padding(.trailing, 20)
        .padding(.bottom, bottomPadding)
        .accessibilityLabel("Simulate site approach")
        .sheet(isPresented: $isShowingSheet) {
            SimulateApproachSheet(
                siteGroups: simulatableSitesByDistrict,
                onSelectSite: { site in
                    environment.proximity.simulateTrigger(site: site)
                    isShowingSheet = false
                }
            )
        }
    }
}
