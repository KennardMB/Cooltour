import SwiftUI
import MapKit

struct MapView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var selectedSite: Site?
    @State private var showDebugRadius = false
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Map(position: $cameraPosition, selection: $selectedSite) {
                    UserAnnotation()
                    
                    ForEach(environment.content.allSites()) { site in
                        Annotation(site.name, coordinate: CLLocationCoordinate2D(latitude: site.latitude, longitude: site.longitude)) {
                            VStack(spacing: 0) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.blue)
                                    .background(Circle().fill(.white))
                            }
                            .tag(site)
                        }
                        
                        if showDebugRadius {
                            MapCircle(center: CLLocationCoordinate2D(latitude: site.latitude, longitude: site.longitude), radius: site.triggerRadiusMeters)
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
                    Image(systemName: showDebugRadius ? "circle.dashed.inset.filled" : "circle.dashed")
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .padding()
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedSite) { site in
                SiteDetailSheet(site: site)
            }
            .onAppear {
                if environment.permissions.authorizationStatus == .notDetermined {
                    environment.permissions.requestLocationPermission()
                }
            }
        }
    }
}

#Preview {
    MapView()
        .environment(AppEnvironment())
}
