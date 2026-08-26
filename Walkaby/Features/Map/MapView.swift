import MapKit
import SwiftUI

struct MapView: View {
  @Environment(AppEnvironment.self) private var environment
  @Environment(\.dismiss) private var dismiss
  @State private var selectedSite: Site?
  @State private var showDebugRadius = false
  @State private var cameraPosition: MapCameraPosition = .userLocation(
    fallback: .automatic
  )
  @State private var isMapReady = false

  var body: some View {
    NavigationStack {
      ZStack {
        if isMapReady {
          ZStack(alignment: .bottomTrailing) {
            Map(position: $cameraPosition, selection: $selectedSite) {
              UserAnnotation()

              let visibleSites = environment.content.allSites()

              ForEach(visibleSites) { site in
                Annotation(
                  site.name,
                  coordinate: CLLocationCoordinate2D(
                    latitude: site.latitude,
                    longitude: site.longitude
                  )
                ) {
                  VStack(spacing: 0) {
                    Image(systemName: "mappin.circle.fill")
                      .font(.title)
                      .foregroundColor(.blue)
                      .background(Circle().fill(.white))
                  }
                  .onTapGesture {
                    selectedSite = site
                  }
                  .tag(site)
                }

                if showDebugRadius {
                  MapCircle(
                    center: CLLocationCoordinate2D(
                      latitude: site.latitude,
                      longitude: site.longitude
                    ),
                    radius: site.triggerRadiusMeters
                  )
                  .foregroundStyle(.blue.opacity(0.1))
                  .stroke(.blue, lineWidth: 1)
                }
              }
            }
            .mapControls {
              MapUserLocationButton()
              MapCompass()
              MapScaleView()
            }

            // Debug Toggle
            Button {
              showDebugRadius.toggle()
            } label: {
              Image(
                systemName: showDebugRadius
                  ? "circle.dashed.inset.filled" : "circle.dashed"
              )
              .padding()
              .background(.ultraThinMaterial)
              .clipShape(Circle())
            }
            .padding()
          }
        } else {
          VStack(spacing: 16) {
            ProgressView()
              .scaleEffect(1.5)
            Text("Loading Map...")
              .foregroundColor(.secondary)
          }
        }
      }
      .navigationTitle("Map")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            dismiss()
          } label: {
            Image(systemName: "xmark.circle.fill")
              .font(.system(size: 22))
              .foregroundStyle(.secondary)
          }
          .buttonStyle(.plain)
          .accessibilityLabel("Close map")
        }
      }
      .sheet(item: $selectedSite) { site in
        SiteDetailSheet(site: site)
      }
      .task {
        // Delay map rendering slightly so the transition is smooth
        try? await Task.sleep(for: .seconds(0.15))
        isMapReady = true
      }
    }
  }
}

#Preview {
  MapView()
    .environment(AppEnvironment())
}
