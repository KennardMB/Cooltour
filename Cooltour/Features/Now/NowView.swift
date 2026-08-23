import CoreLocation
import MapKit
import SwiftUI

// MARK: - Now View (Figma Nodes 223:1335 & 223:1414)

struct NowView: View {
    @Environment(AppEnvironment.self) private var env
    @AppStorage("user_profile_name") private var userName: String = "Anton B."

    @State private var isShowingSitesPlayer: Bool = false
    @State private var isShowingProfile: Bool = false
    @State private var isShowingPauseOverlay: Bool = false
    @State private var locationTitle: String = "Live Location"
    @State private var locationSubtitle: String = "Denpasar, Bali, Indonesia"
    @State private var lastGeocodedCoord: CLLocationCoordinate2D?

    private var firstName: String {
        let trimmed = userName.trimmingCharacters(in: .whitespaces)
        return trimmed.components(separatedBy: " ").first ?? "Anton"
    }

    private var userInitial: String {
        String(firstName.prefix(1)).uppercased()
    }

    private var isLocationAuthorized: Bool {
        env.proximity.authorizationStatus == .authorizedWhenInUse || env.proximity.authorizationStatus == .authorizedAlways
    }

    private var nearbySitesCount: Int {
        let count = env.proximity.nearbySites.filter { $0.distanceMeters <= 1000 }.count
        if count > 0 { return count }
        if env.proximity.isListening {
            return env.proximity.nearbySites.count
        }
        return 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // 1. Grid Background Texture (Figma Tile Background #F8F7F4)
                TiledBackgroundView()
                    .ignoresSafeArea()

                // 2. Main Content Canvas
                if env.settings.walkingMode {
                    wanderingContentView
                } else {
                    idleContentView
                }

                // 3. Pause Tour Overlay (Figma Node 209:3795)
                if isShowingPauseOverlay {
                    PauseTourOverlay(
                        onResume: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isShowingPauseOverlay = false
                            }
                        },
                        onEndTour: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isShowingPauseOverlay = false
                                env.settings.walkingMode = false
                                env.proximity.stop()
                                env.audio.stop()
                            }
                        }
                    )
                    .zIndex(10)
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $isShowingSitesPlayer) {
                SitesPlayerView(onOpenMap: {
                    env.selectedTab = .map
                })
            }
            .sheet(isPresented: $isShowingProfile) {
                ProfileView()
            }
            .onAppear {
                updateLocationDisplay()
            }
            .onChange(of: env.proximity.authorizationStatus) { _, _ in
                updateLocationDisplay()
            }
            .onChange(of: env.proximity.lastFix?.latitude) { _, _ in
                updateLocationDisplay()
            }
            .onChange(of: env.narration.state) { _, state in
                if state == .prompting {
                    isShowingSitesPlayer = true
                }
            }
            .onChange(of: env.audio.isPlaying) { _, isPlaying in
                if isPlaying && !isShowingSitesPlayer {
                    isShowingSitesPlayer = true
                }
            }
        }
    }

    // MARK: - Idle State View (Figma Node 223:1335)

    private var idleContentView: some View {
        VStack(spacing: 0) {
            // Top Bar (Live Location Indicator + Profile Avatar)
            HStack(alignment: .center, spacing: 8) {
                // Location Info Column
                Button {
                    handleLocationTap()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isLocationAuthorized ? "location.north.fill" : "location.slash.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(
                                isLocationAuthorized
                                    ? Color(red: 255/255, green: 102/255, blue: 52/255) // #FF6634 Coral
                                    : AppColor.Text.secondary
                            )
                            .frame(width: 32, height: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(locationTitle)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(red: 17/255, green: 17/255, blue: 17/255))

                            Text(locationSubtitle)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(Color(red: 57/255, green: 57/255, blue: 57/255))
                                .lineLimit(1)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(locationTitle): \(locationSubtitle)")
                .accessibilityHint(isLocationAuthorized ? "Shows current city" : "Tap to configure location permissions")

                Spacer()

                // Profile Avatar Button (Figma Node 202:1135)
                Button {
                    isShowingProfile = true
                } label: {
                    ZStack {
                        Image("BrushProfile")
                            .resizable()
                            .frame(width: 40, height: 40)

                        Text(userInitial.isEmpty ? "A" : userInitial)
                            .font(.custom("Baru Lagi", size: 20))
                            .foregroundStyle(Color(red: 29/255, green: 82/255, blue: 216/255)) // #1D52D8
                    }
                    .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Profile of \(firstName)")
                .accessibilityHint("Opens profile overview")
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            Spacer(minLength: 20)

            // Hero Sketch Illustration (Placeholder ready for animated drop-in)
            NowHeroIllustrationView()
                .frame(maxWidth: 360, maxHeight: 300)
                .padding(.horizontal, 20)

            Spacer(minLength: 20)

            // Bottom Greeting & Start Exploration Action
            VStack(alignment: .leading, spacing: 14) {
                // Greeting Header (Baru Lagi 32pt)
                HStack(spacing: 0) {
                    Text("hi, ")
                        .font(.custom("Baru Lagi", size: 32))
                        .foregroundStyle(Color(red: 17/255, green: 17/255, blue: 17/255))

                    Text("\(firstName.isEmpty ? "Anton" : firstName)!")
                        .font(.custom("Baru Lagi", size: 32))
                        .foregroundStyle(Color(red: 255/255, green: 102/255, blue: 52/255)) // #FF6634
                }
                .padding(.horizontal, 4)

                // Start Exploration Button (Figma Node 204:2055)
                Button {
                    startExploration()
                } label: {
                    Image("BrushButtonPlayActive")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 60)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Start exploration")
                .accessibilityHint("Begins GPS listening and starts wandering")
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
    }

    // MARK: - Wandering / Exploring State View (Figma Node 223:1414)

    private var wanderingContentView: some View {
        VStack(spacing: 0) {
            // Top Bar: "You are now in" + Red "pause" Button
            HStack(alignment: .center, spacing: 8) {
                // Location Info Column (Blue Icon)
                Button {
                    handleLocationTap()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color(red: 29/255, green: 82/255, blue: 216/255)) // #1D52D8
                            .frame(width: 32, height: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("You are now in")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color(red: 57/255, green: 57/255, blue: 57/255))

                            Text(locationSubtitle)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(Color(red: 57/255, green: 57/255, blue: 57/255))
                                .lineLimit(1)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Location: \(locationSubtitle)")

                Spacer()

                // Red Destructive Pause Button (100x40pt)
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isShowingPauseOverlay = true
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(red: 216/255, green: 29/255, blue: 29/255)) // #D81D1D
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .strokeBorder(Color(red: 130/255, green: 17/255, blue: 17/255), lineWidth: 4) // #821111
                            )
                            .frame(width: 100, height: 40)

                        Text("pause")
                            .font(.custom("Baru Lagi", size: 16))
                            .foregroundStyle(Color(red: 254/255, green: 254/255, blue: 254/255))
                    }
                    .frame(width: 100, height: 40)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Pause tour")
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            Spacer(minLength: 12)

            // Center Top: Pulsating Location Dot + Headline
            VStack(spacing: 14) {
                PulsatingLocationDot()

                if nearbySitesCount > 0 {
                    Text("\(nearbySitesCount) sites detected\naround you!")
                        .font(.custom("Baru Lagi", size: 20))
                        .foregroundStyle(Color(red: 29/255, green: 82/255, blue: 216/255)) // #1D52D8
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                } else {
                    Text("No site yet,\nkeep wandering!")
                        .font(.custom("Baru Lagi", size: 20))
                        .foregroundStyle(Color(red: 29/255, green: 82/255, blue: 216/255)) // #1D52D8
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }
            .padding(.top, 8)

            Spacer(minLength: 12)

            // Center: Hero Illustration
            NowHeroIllustrationView()
                .frame(maxWidth: 360, maxHeight: 270)
                .padding(.horizontal, 20)

            Spacer(minLength: 12)

            // Bottom Content: Caption + "open map" Button
            VStack(spacing: 16) {
                Text(nearbySitesCount > 0 ? "keep wandering until you passed by one!" : "keep wandering to discover cultural stories!")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Color(red: 104/255, green: 104/255, blue: 102/255)) // #686866
                    .multilineTextAlignment(.center)

                // Open Map Button (Figma Node 223:1426)
                Button {
                    env.selectedTab = .map
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(red: 29/255, green: 82/255, blue: 216/255)) // #1D52D8
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .strokeBorder(Color(red: 17/255, green: 49/255, blue: 130/255), lineWidth: 4) // #113182
                            )
                            .frame(height: 50)

                        Text("open map")
                            .font(.custom("Baru Lagi", size: 18))
                            .foregroundStyle(Color(red: 254/255, green: 254/255, blue: 254/255))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open map")
                .accessibilityHint("Opens the full map view")
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
    }

    // MARK: - Actions & Logic

    private func startExploration() {
        withAnimation(.easeInOut(duration: 0.3)) {
            env.settings.walkingMode = true
        }
        env.proximity.start()
        Task {
            _ = await env.notifications.requestAuthorization()
        }
    }

    private func handleLocationTap() {
        switch env.proximity.authorizationStatus {
        case .denied, .restricted:
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        case .notDetermined:
            env.proximity.start()
        default:
            break
        }
    }

    private func updateLocationDisplay() {
        switch env.proximity.authorizationStatus {
        case .denied, .restricted:
            locationTitle = "Location Off"
            locationSubtitle = "Turn on in Settings to start exploring"
        case .notDetermined:
            locationTitle = "Enable Location"
            locationSubtitle = "Tap to allow GPS for live audio stories"
        case .authorizedWhenInUse, .authorizedAlways:
            locationTitle = "Live Location"
            if let fix = env.proximity.lastFix {
                reverseGeocodeCoord(latitude: fix.latitude, longitude: fix.longitude)
            } else if let nearest = env.proximity.nearbySites.first,
                      let site = env.content.allSites().first(where: { $0.slug == nearest.id }),
                      !site.districtName.isEmpty {
                locationSubtitle = formatDistrict(site.districtName)
            } else {
                locationSubtitle = "Denpasar, Bali, Indonesia"
            }
        @unknown default:
            locationTitle = "Live Location"
            locationSubtitle = "Denpasar, Bali, Indonesia"
        }
    }

    private func reverseGeocodeCoord(latitude: Double, longitude: Double) {
        if let last = lastGeocodedCoord {
            let loc1 = CLLocation(latitude: last.latitude, longitude: last.longitude)
            let loc2 = CLLocation(latitude: latitude, longitude: longitude)
            if loc1.distance(from: loc2) < 250 {
                return
            }
        }
        lastGeocodedCoord = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let location = CLLocation(latitude: latitude, longitude: longitude)

        Task {
            guard let request = MKReverseGeocodingRequest(location: location) else { return }
            do {
                let mapItems = try await request.mapItems
                if let item = mapItems.first {
                    if let cityContext = item.addressRepresentations?.cityWithContext, !cityContext.isEmpty {
                        self.locationSubtitle = cityContext
                    } else if let name = item.name, !name.isEmpty {
                        self.locationSubtitle = "\(name), Bali, Indonesia"
                    }
                }
            } catch {
                if let nearest = env.proximity.nearbySites.first,
                   let site = env.content.allSites().first(where: { $0.slug == nearest.id }),
                   !site.districtName.isEmpty {
                    self.locationSubtitle = formatDistrict(site.districtName)
                }
            }
        }
    }

    private func formatDistrict(_ district: String) -> String {
        let parts = district.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        if parts.count >= 3 {
            return "\(parts[0]), \(parts[1]), \(parts[2])"
        } else if parts.count == 2 {
            return "\(parts[0]), \(parts[1]), Indonesia"
        } else if parts.count == 1 {
            return "\(parts[0]), Bali, Indonesia"
        }
        return "Denpasar, Bali, Indonesia"
    }
}

// MARK: - Pulsating Location Dot

private struct PulsatingLocationDot: View {
    @State private var isPulsing: Bool = false

    var body: some View {
        ZStack {
            // Outer soft pulse ring
            Circle()
                .fill(Color(red: 29/255, green: 82/255, blue: 216/255).opacity(isPulsing ? 0.12 : 0.35))
                .frame(width: 76, height: 76)
                .scaleEffect(isPulsing ? 1.25 : 0.85)

            // Middle pulse ring
            Circle()
                .fill(Color(red: 29/255, green: 82/255, blue: 216/255).opacity(isPulsing ? 0.30 : 0.55))
                .frame(width: 58, height: 58)
                .scaleEffect(isPulsing ? 1.12 : 0.9)

            // Core solid location circle
            Circle()
                .fill(Color(red: 29/255, green: 82/255, blue: 216/255)) // #1D52D8
                .frame(width: 44, height: 44)
        }
        .frame(width: 80, height: 80)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

#Preview("Now View - Idle") {
    NowView()
        .environment(AppEnvironment())
}
