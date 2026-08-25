import CoreLocation
import MapKit
import SwiftUI

// MARK: - Now View (Figma Nodes 223:1335, 223:1414 & 223:1448)

struct NowView: View {
    @Environment(AppEnvironment.self) private var env
    @AppStorage("user_profile_name") private var userName: String = "Anton B."

    @State private var isShowingSitesPlayer: Bool = false
    @State private var isShowingProfile: Bool = false
    @State private var isShowingPauseOverlay: Bool = false
    @State private var isShowingSimulateApproachSheet: Bool = false
    @State private var showQueueToast: Bool = false
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
        guard env.proximity.isListening else { return 0 }
        return env.proximity.nearbySites.filter { $0.distanceMeters <= 1000 }.count
    }

    var body: some View {
        NavigationStack {
            // Opens Observation scopes
            ObservingNarration(coordinator: env.narration) { narrationState, prompt, countdown in
                ZStack {
                    // 1. Grid Background Texture (Figma Tile Background #F8F7F4)
                    TiledBackgroundView()
                        .ignoresSafeArea()

                    // 2. Main Content State Machine
                    if !env.settings.walkingMode {
                        // State A: Idle Home Screen (Figma Node 223:1335)
                        idleContentView
                    } else if narrationState == .prompting, let prompt {
                        // State C: Discovered Site Prompt (Figma Node 223:1448)
                        discoveredSitePromptView(prompt: prompt, countdown: countdown)
                    } else {
                        // State B: Wandering / Exploring Screen (Figma Node 223:1414)
                        wanderingContentView
                    }

                    // 3. Queue Toast / Snackbar Notification
                    if showQueueToast {
                        queueToastView
                    }

                    // 4. Pause Tour Overlay (Figma Node 209:3795)
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
            .sheet(isPresented: $isShowingSimulateApproachSheet) {
                SimulateApproachSheet(
                    siteGroups: simulatableSitesByDistrict,
                    onSelectSite: { site in
                        env.proximity.simulateTrigger(site: site)
                        isShowingSimulateApproachSheet = false
                    }
                )
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
        }
    }

    // MARK: - State A: Idle Home Screen (Figma Node 223:1335)

    /// Loaded sites grouped by district for the Simulate-approach menu, keeping each
    /// region's sites together (e.g. all Renon sites in one section) instead of one flat list.
    private var simulatableSitesByDistrict: [(district: String, sites: [Site])] {
        Dictionary(grouping: env.content.allSites(), by: \.districtName)
            .map { (district: $0.key, sites: $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.district < $1.district }
    }

    private var idleContentView: some View {
        VStack(spacing: 0) {
            // Top Bar (Live Location Indicator + Profile Avatar)
            HStack(alignment: .center, spacing: 8) {
                // Location Info Column
                Button {
                    handleLocationTap()
                } label: {
                    HStack(spacing: 8) {
                        Image(isLocationAuthorized ? "IconLocationActive" : "IconLocationInactive")
                            .resizable()
                            .scaledToFit()
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

    // MARK: - State B: Wandering / Exploring Screen (Figma Node 223:1414)

    private var wanderingContentView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Top Bar: "You are now in" + Red "pause" Button
                HStack(alignment: .center, spacing: 8) {
                    // Location Info Column (SVG Location Icon)
                    Button {
                        handleLocationTap()
                    } label: {
                        HStack(spacing: 8) {
                            Image(isLocationAuthorized ? "IconLocationActive" : "IconLocationInactive")
                                .resizable()
                                .scaledToFit()
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

                    // Red Brush Pause Button (112x40pt, Figma Node 241:1593)
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isShowingPauseOverlay = true
                        }
                    } label: {
                        Image("BrushButtonPause")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 112, height: 40)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Pause tour")
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

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
                        Text("No Site yet,\nKeep Wandering!")
                            .font(.custom("Baru Lagi", size: 20))
                            .foregroundStyle(Color(red: 29/255, green: 82/255, blue: 216/255)) // #1D52D8
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                }
                .padding(.top, 24)

                // Center: Hero Illustration
                NowHeroIllustrationView()
                    .frame(maxWidth: 360, maxHeight: 270)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                // Bottom Content: Caption + "open map" Button
                VStack(spacing: 16) {
                    // Temporary Slice 11 debug — fires the consent prompt as if you walked up to a site.
                    Button {
                        isShowingSimulateApproachSheet = true
                    } label: {
                        Text("Simulate site approach")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color(red: 29/255, green: 82/255, blue: 216/255))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(red: 254/255, green: 254/255, blue: 254/255))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .strokeBorder(Color(red: 232/255, green: 238/255, blue: 251/255), lineWidth: 4)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Pick any site to fire its consent prompt as if you walked up to it.")

                    Text(nearbySitesCount > 0 ? "keep wandering until you passed by one!" : "keep wandering to discover cultural stories!")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(Color(red: 104/255, green: 104/255, blue: 102/255)) // #686866
                        .multilineTextAlignment(.center)

                    // Open Map Button (Figma Node 241:1618)
                    Button {
                        env.selectedTab = .map
                    } label: {
                        Image("BrushButtonOpenMap")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open map")
                    .accessibilityHint("Opens the full map view")
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 28)
            }
        }
    }

    // MARK: - State C: Discovered Site Prompt (Figma Node 223:1448)

    private func discoveredSitePromptView(prompt: PendingPrompt, countdown: Int?) -> some View {
        let site = env.content.allSites().first { $0.name == prompt.siteName || $0.slug == prompt.siteSlug }
        let hasMultipleSitesInRange = nearbySitesCount > 1
        let languageCode = env.settings.resolvedLanguageCode
        let queueAction = ConsentStrings.addToQueueAction(languageCode: languageCode)
        let playAction = ConsentStrings.playNowAction(languageCode: languageCode)

        return ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // 1. Top Bar: "You are now in" + Red "pause" Button
                HStack(alignment: .center, spacing: 8) {
                    Button {
                        handleLocationTap()
                    } label: {
                        HStack(spacing: 8) {
                            Image(isLocationAuthorized ? "IconLocationActive" : "IconLocationInactive")
                                .resizable()
                                .scaledToFit()
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

                    Spacer()

                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isShowingPauseOverlay = true
                        }
                    } label: {
                        Image("BrushButtonPause")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 112, height: 40)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Pause tour")
                }

                // 2. Detection Strip Card (Figma Node 223:1466)
                HStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(red: 29/255, green: 82/255, blue: 216/255))
                            .frame(width: 12, height: 12)

                        Text("\(max(1, nearbySitesCount)) sites detected near you!")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(Color(red: 104/255, green: 104/255, blue: 102/255)) // #686866
                    }

                    Spacer()

                    Button {
                        env.selectedTab = .map
                    } label: {
                        Text("Open Map")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color(red: 29/255, green: 82/255, blue: 216/255)) // #1D52D8
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(red: 254/255, green: 254/255, blue: 254/255))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color(red: 232/255, green: 238/255, blue: 251/255), lineWidth: 4) // #E8EEFB
                )

                // 3. Photo Polaroid Card (Figma Node 223:1450)
                VStack(alignment: .leading, spacing: 8) {
                    ZStack {
                        if let siteImage = loadSiteImage(name: site?.thumbnailAssetName) {
                            Image(uiImage: siteImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 240)
                                .frame(maxWidth: .infinity)
                                .clipped()
                        } else {
                            Rectangle()
                                .fill(Color(red: 232/255, green: 238/255, blue: 251/255))
                                .frame(height: 240)
                                .overlay(
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.system(size: 44))
                                        .foregroundStyle(Color(red: 29/255, green: 82/255, blue: 216/255).opacity(0.6))
                                )
                        }
                    }
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                    Text("Source: ADA.com")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color(red: 104/255, green: 104/255, blue: 102/255))
                        .padding(.leading, 4)
                }
                .padding(8)
                .background(Color(red: 254/255, green: 254/255, blue: 254/255))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .shadow(color: Color.black.opacity(0.18), radius: 6, x: 2, y: 3)

                // 4. Site Name & Headline (Figma Node 223:1460)
                VStack(alignment: .leading, spacing: 4) {
                    Text(prompt.siteName)
                        .font(.custom("Baru Lagi", size: 28))
                        .foregroundStyle(Color(red: 29/255, green: 82/255, blue: 216/255)) // #1D52D8
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("\(prompt.siteName) is in your radar! Would you like to learn more about it?")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(Color(red: 10/255, green: 10/255, blue: 10/255))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 4)

                // 5. Action Buttons (Row 1: Add to queue + Play now)
                HStack(spacing: 12) {
                    // "add to queue" button
                    if hasMultipleSitesInRange {
                        Button {
                            env.narration.queue(promptID: prompt.id)
                            triggerQueueToast()
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(red: 255/255, green: 102/255, blue: 52/255)) // #FF6634
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .strokeBorder(Color(red: 196/255, green: 75/255, blue: 37/255), lineWidth: 4) // #C44B25
                                    )
                                    .frame(height: 60)

                                Text(queueAction)
                                    .font(.custom("Baru Lagi", size: 16))
                                    .foregroundStyle(Color(red: 254/255, green: 254/255, blue: 254/255))
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(queueAction) \(prompt.siteName)")
                    } else {
                        // Disabled State
                        ZStack {
                            Image("BrushButtonDefaultDisabled")
                                .resizable()
                                .frame(height: 60)

                            Text(queueAction)
                                .font(.custom("Baru Lagi", size: 16))
                                .foregroundStyle(Color(red: 158/255, green: 158/255, blue: 158/255))
                        }
                        .frame(height: 60)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(queueAction) disabled, only one site in range")
                    }

                    // "play now" button
                    Button {
                        env.narration.accept(promptID: prompt.id)
                        isShowingSitesPlayer = true
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(red: 29/255, green: 82/255, blue: 216/255)) // #1D52D8
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .strokeBorder(Color(red: 17/255, green: 49/255, blue: 130/255), lineWidth: 4) // #113182
                                )
                                .frame(height: 60)

                            Text(playAction)
                                .font(.custom("Baru Lagi", size: 16))
                                .foregroundStyle(Color(red: 254/255, green: 254/255, blue: 254/255))
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(playAction) \(prompt.siteName)")
                }

                // 6. Dismiss Button (Row 2: dismiss....(10s))
                Button {
                    env.narration.dismiss(promptID: prompt.id)
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(red: 254/255, green: 254/255, blue: 254/255).opacity(0.85))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .strokeBorder(Color(red: 226/255, green: 225/255, blue: 222/255), lineWidth: 4) // #E2E1DE
                            )
                            .frame(height: 56)

                        Text(
                            ConsentStrings.dismissWithCountdown(
                                countdown ?? 10,
                                languageCode: languageCode
                            )
                        )
                            .font(.custom("Baru Lagi", size: 16))
                            .foregroundStyle(Color(red: 104/255, green: 104/255, blue: 102/255)) // #686866
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    ConsentStrings.dismissAction(languageCode: languageCode)
                )
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 28)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(
                ConsentStrings.storyPromptAccessibility(
                    siteName: prompt.siteName,
                    languageCode: languageCode
                )
            )
        }
    }

    // MARK: - Queue Toast / Snackbar View

    private var queueToastView: some View {
        VStack {
            Spacer()

            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color(red: 1/255, green: 181/255, blue: 82/255)) // #01B552

                Text("Added to queue")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.white)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showQueueToast = false
                    }
                    isShowingSitesPlayer = true
                } label: {
                    Text("Open")
                        .font(.custom("Baru Lagi", size: 16))
                        .foregroundStyle(Color(red: 255/255, green: 102/255, blue: 52/255)) // #FF6634
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.18))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open queue")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(red: 27/255, green: 27/255, blue: 27/255))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.24), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .zIndex(20)
    }

    // MARK: - Actions & Helpers

    private func triggerQueueToast() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            showQueueToast = true
        }
        Task {
            try? await Task.sleep(nanoseconds: 3_500_000_000)
            withAnimation(.easeInOut(duration: 0.25)) {
                showQueueToast = false
            }
        }
    }

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

    private func loadSiteImage(name: String?) -> UIImage? {
        guard let name, !name.isEmpty else { return nil }
        if let img = UIImage(named: name) { return img }
        if let path = Bundle.main.path(forResource: name, ofType: nil, inDirectory: "SitePictures"),
           let img = UIImage(contentsOfFile: path) { return img }
        let base = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension.isEmpty ? "jpg" : (name as NSString).pathExtension
        if let url = Bundle.main.url(forResource: base, withExtension: ext),
           let data = try? Data(contentsOf: url),
           let img = UIImage(data: data) { return img }
        return nil
    }
}

// MARK: - Simulate Approach Sheet

/// Scrollable site picker for debug simulate-approach — a `Menu` resets while scrolling
/// when the parent view re-renders from live GPS updates.
private struct SimulateApproachSheet: View {
    @Environment(\.dismiss) private var dismiss

    let siteGroups: [(district: String, sites: [Site])]
    let onSelectSite: (Site) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(siteGroups, id: \.district) { group in
                    Section(group.district) {
                        ForEach(group.sites, id: \.slug) { site in
                            Button(site.name) {
                                onSelectSite(site)
                            }
                            .foregroundStyle(AppColor.Text.primary)
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
