import CoreLocation
import SwiftUI

// MARK: - Sites Player Screen (Figma Node 209:3233)

public struct SitesPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var env

    public var onOpenMap: (() -> Void)?

    @State private var currentSiteIndex: Int = 0
    @State private var isShowingFullTranscript: Bool = false
    @State private var isShowingQueueSheet: Bool = false
    @State private var isShowingPauseOverlay: Bool = false
    @State private var isShowingSpeedSheet: Bool = false
    @State private var isScrubbing: Bool = false
    @State private var scrubProgress: Double = 0.0

    public init(onOpenMap: (() -> Void)? = nil) {
        self.onOpenMap = onOpenMap
    }

    public var body: some View {
        ObservingAudio(audio: env.audio) { isPlaying, isLoading, currentStory, progress in
            let sites = availableSites()
            let playingSite = Self.siteForStory(currentStory, in: sites)
            let carouselSite = sites.indices.contains(currentSiteIndex) ? sites[currentSiteIndex] : sites.first
            // Follow the loaded story for metadata and controls; carousel is for browsing other stops.
            let activeSite = playingSite ?? carouselSite
            let activeStory = currentStory ?? carouselSite?.stories.first
            let duration = max(1.0, activeStory?.durationSeconds(for: env.settings.audioLanguage) ?? 180.0)
            let effectiveProgress = isScrubbing ? scrubProgress : progress
            let currentTime = effectiveProgress * duration
            let remainingTime = max(0, duration - currentTime)

            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    // 1. Top Header: Location Indicator & Pause Button
                    HStack(spacing: 12) {
                        // Regional Location Indicator
                        HStack(spacing: 8) {
                            Image(env.proximity.authorizationStatus == .authorizedWhenInUse || env.proximity.authorizationStatus == .authorizedAlways ? "IconLocationActive" : "IconLocationInactive")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("You are now in")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Color(red: 57/255, green: 57/255, blue: 57/255))

                                Text(currentRegionalLocationString(activeSite: activeSite))
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundStyle(Color(red: 104/255, green: 104/255, blue: 102/255))
                                    .lineLimit(1)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Pause Walk Button (Figma Node 241:1593)
                        Button {
                            env.audio.pause()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isShowingPauseOverlay = true
                            }
                        } label: {
                            Image("BrushButtonPause")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 112, height: 40)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Pause walk")
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.sm)

                    // 2. Nearby POI Detection Banner ("X sites detected near you! Open Map")
                    let nearbyCount = countNearbyPOIs()
                    if nearbyCount > 0 {
                        HStack {
                            HStack(spacing: 8) {
                                // Pulsating glowing orange dot
                                ZStack {
                                    Circle()
                                        .fill(Color(red: 255/255, green: 102/255, blue: 52/255).opacity(0.3))
                                        .frame(width: 16, height: 16)

                                    Circle()
                                        .fill(Color(red: 255/255, green: 102/255, blue: 52/255))
                                        .frame(width: 8, height: 8)
                                }

                                Text("\(nearbyCount) site\(nearbyCount > 1 ? "s" : "") detected near you!")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundStyle(Color(red: 104/255, green: 104/255, blue: 102/255))
                            }

                            Spacer()

                            Button {
                                env.selectedTab = .map
                                onOpenMap?()
                                dismiss()
                            } label: {
                                Text("Open Map")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Color(red: 255/255, green: 102/255, blue: 52/255))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Open Map")
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(Color(red: 255/255, green: 218/255, blue: 206/255), lineWidth: 4) // #FFDACE
                        )
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, 14)
                    }

                    Spacer(minLength: 4)

                    // 3. Photo Carousel Card (Swipeable Stops)
                    TabView(selection: $currentSiteIndex) {
                        ForEach(Array(sites.enumerated()), id: \.element.id) { index, site in
                            SitePhotoCard(site: site)
                                .tag(index)
                                .padding(.horizontal, AppSpacing.lg)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 275)

                    Spacer(minLength: 4)

                    // 4. Site Name & District
                    VStack(alignment: .leading, spacing: 3) {
                        Text(activeSite?.name ?? "Cultural Site")
                            .font(.custom(AppTextStyle.customFontPostScriptName, size: 26))
                            .foregroundStyle(AppColor.Brand.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(currentRegionalLocationString(activeSite: activeSite))
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(AppColor.Text.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppSpacing.lg)

                    Spacer(minLength: 4)

                    // 5. Tactile Audio Scrubber Component
                    AudioScrubber(
                        progress: Binding(
                            get: { effectiveProgress },
                            set: { newProgress in
                                env.audio.seek(toProgress: newProgress)
                            }
                        ),
                        durationSeconds: duration,
                        isInteractive: true,
                        onSeek: { seconds in
                            env.audio.seek(toProgress: seconds / duration)
                        }
                    )
                    .padding(.horizontal, AppSpacing.lg)

                    Spacer(minLength: 4)

                    // 6. Audio Control Toolbar with AppIcon
                    HStack(spacing: 24) {
                        // A. Playback Speed Button (Opens Half Sheet)
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isShowingSpeedSheet = true
                            }
                        } label: {
                            AppIcon(AppIconType.forSpeed(env.settings.defaultPlaybackSpeed), size: 40)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Playback speed")

                        // B. Rewind 10 Seconds
                        Button {
                            let newProgress = max(0, effectiveProgress - (10.0 / duration))
                            env.audio.seek(toProgress: newProgress)
                        } label: {
                            AppIcon(.rewind10, size: 36)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Rewind 10 seconds")

                        // C. Primary Chunky Play / Pause Button (60x60)
                        Button {
                            if isPlaying {
                                env.audio.pause()
                            } else if env.audio.currentStory?.slug == activeStory?.slug {
                                env.audio.resume()
                            } else if let activeStory {
                                env.audio.play(story: activeStory)
                            }
                        } label: {
                            AppIcon(isPlaying ? .pause : .play, size: 60)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(isPlaying ? "Pause" : "Play")

                        // D. Forward 10 Seconds
                        Button {
                            let newProgress = min(1.0, effectiveProgress + (10.0 / duration))
                            env.audio.seek(toProgress: newProgress)
                        } label: {
                            AppIcon(.forward10, size: 36)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Forward 10 seconds")

                        // E. Queue List Button (Opens Half Sheet)
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isShowingQueueSheet = true
                            }
                        } label: {
                            AppIcon(.queue, size: 36)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Story Queue")
                    }
                    .padding(.top, 2)

                    Spacer(minLength: 6)

                    // 7. Transcription Bottom Drawer Card
                    Button {
                        isShowingFullTranscript = true
                    } label: {
                        TranscriptionPreviewCard(
                            siteName: activeSite?.name ?? "Cultural Site"
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, 10)
                }

                // 8. Pause Tour Modal Overlay (Figma Node 209:3795)
                if isShowingPauseOverlay {
                    PauseTourOverlay(
                        onResume: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isShowingPauseOverlay = false
                            }
                            env.audio.resume()
                        },
                        onEndTour: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isShowingPauseOverlay = false
                            }
                            env.audio.stop()
                            env.proximity.stop()
                            env.history.stopWalk()
                            env.storyQueue.clear()
                            env.settings.walkingMode = false
                            dismiss()
                        }
                    )
                }

                // 9. Playback Speed Picker Bottom Sheet (Figma Node 210:1033)
                if isShowingSpeedSheet {
                    ZStack(alignment: .bottom) {
                        // Semi-opaque backdrop (tap to dismiss)
                        Color(red: 226/255, green: 225/255, blue: 222/255)
                            .opacity(0.90)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isShowingSpeedSheet = false
                                }
                            }

                        PlaybackSpeedSheet(
                            selectedSpeed: Binding(
                                get: { env.settings.defaultPlaybackSpeed },
                                set: { newSpeed in
                                    env.settings.defaultPlaybackSpeed = newSpeed
                                    env.audio.setRate(Float(newSpeed))
                                }
                            ),
                            onSelect: { newSpeed in
                                env.settings.defaultPlaybackSpeed = newSpeed
                                env.audio.setRate(Float(newSpeed))
                            },
                            onClose: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isShowingSpeedSheet = false
                                }
                            }
                        )
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .transition(.opacity)
                }

                // 10. Queue List Bottom Sheet (Figma Node 210:1078)
                if isShowingQueueSheet {
                    ObservingQueue(queue: env.storyQueue) { queueItems in
                        ZStack(alignment: .bottom) {
                            // Semi-opaque backdrop (tap to dismiss)
                            Color(red: 226/255, green: 225/255, blue: 222/255)
                                .opacity(0.90)
                                .ignoresSafeArea()
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isShowingQueueSheet = false
                                    }
                                }

                            StoryQueueSheet(
                                currentStory: activeStory,
                                activeSiteName: activeSite?.name ?? "Current Stop",
                                remainingTime: remainingTime,
                                isPlaying: isPlaying,
                                queueItems: queueItems,
                                onTogglePlayback: {
                                    if isPlaying {
                                        env.audio.pause()
                                    } else {
                                        env.audio.resume()
                                    }
                                },
                                onClose: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isShowingQueueSheet = false
                                    }
                                }
                            )
                            .padding(.bottom, 24)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        .transition(.opacity)
                    }
                }

                // Global Floating Simulate Site Approach Button
                FloatingSimulateButton(bottomPadding: 32)
            }
            .defaultTiledBackground(scale: 0.20)
            .sheet(isPresented: $isShowingFullTranscript) {
                FullTranscriptSheet(
                    site: activeSite,
                    story: activeStory,
                    district: currentRegionalLocationString(activeSite: activeSite)
                )
                .presentationDetents([.large])
            }
            .onAppear {
                syncSiteIndexToPlayingStory(currentStory, in: sites)
            }
            .onChange(of: currentStory?.slug) { _, _ in
                syncSiteIndexToPlayingStory(currentStory, in: sites)
            }
            .onChange(of: env.narration.state) { _, newState in
                if newState == .prompting {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Logic Helpers

    private func availableSites() -> [Site] {
        let sites = env.content.allSites()
        return sites.isEmpty ? [] : sites
    }

    static func siteForStory(_ story: Story?, in sites: [Site]) -> Site? {
        guard let story else { return nil }
        return sites.first { site in
            site.stories.contains { $0.slug == story.slug }
        }
    }

    static func siteIndex(for story: Story?, in sites: [Site]) -> Int? {
        guard let playingSite = siteForStory(story, in: sites) else { return nil }
        return sites.firstIndex(where: { $0.slug == playingSite.slug })
    }

    private func syncSiteIndexToPlayingStory(_ story: Story?, in sites: [Site]) {
        guard let index = Self.siteIndex(for: story, in: sites) else { return }
        if currentSiteIndex != index {
            currentSiteIndex = index
        }
    }

    private func countNearbyPOIs() -> Int {
        env.proximity.nearbySites.filter { $0.distanceMeters <= 1000 }.count
    }

    /// Strictly formats the regional location indicator to 3 comma-separated terms.
    /// Example: "Denpasar, Bali, Indonesia" or "Renon, Denpasar, Bali"
    private func currentRegionalLocationString(activeSite: Site?) -> String {
        if let district = activeSite?.districtName, !district.isEmpty {
            let parts = district.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count >= 3 {
                return "\(parts[0]), \(parts[1]), \(parts[2])"
            } else if parts.count == 2 {
                return "\(parts[0]), \(parts[1]), Indonesia"
            } else if parts.count == 1 {
                return "\(parts[0]), Bali, Indonesia"
            }
        }
        return "Denpasar, Bali, Indonesia"
    }
}

// MARK: - Photo Carousel Card

private struct SitePhotoCard: View {
    let site: Site

    var body: some View {
        VStack(spacing: 6) {
            Text("Slide left or right for previous or next stops")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(AppColor.Text.secondary)
                .padding(.top, 2)

            // Main Site Image Display
            ZStack {
                if let image = loadSiteImage(name: site.thumbnailAssetName) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        AppColor.Brand.tint
                        VStack(spacing: 6) {
                            AppIcon(.placeVisited, size: 40)
                            Text(site.name)
                                .font(.custom(AppTextStyle.customFontPostScriptName, size: 18))
                                .foregroundStyle(AppColor.Brand.primary)
                        }
                    }
                }
            }
            .frame(height: 205)
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .clipped()

            HStack {
                Text("Source: ADA.com")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(AppColor.Text.secondary)
                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 2)
        }
        .padding(8)
        .background(AppColor.Background.pure)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.standard))
        .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 3)
    }

    private func loadSiteImage(name: String?) -> UIImage? {
        AssetResolver.siteImage(named: name)
    }
}

// MARK: - Transcription Preview Drawer Card (Figma Node 209:3233)

private struct TranscriptionPreviewCard: View {
    let siteName: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Transcription")
                    .font(.custom(AppTextStyle.customFontPostScriptName, size: 18))
                    .foregroundStyle(Color.white)

                Text(siteName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.95))
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.up")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color(red: 255/255, green: 102/255, blue: 52/255)) // #FF6634 Coral
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Full Transcript Sheet (Figma Node 210:1123)

private struct FullTranscriptSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var env
    let site: Site?
    let story: Story?
    let district: String

    @State private var isScrubbing: Bool = false
    @State private var scrubProgress: Double = 0.0

    var body: some View {
        ObservingAudio(audio: env.audio) { isPlaying, isLoading, currentStory, progress in
            let effectiveStory = story ?? currentStory
            let duration = max(1.0, effectiveStory?.durationSeconds(for: env.settings.audioLanguage) ?? 180.0)
            let effectiveProgress = isScrubbing ? scrubProgress : progress
            let transcriptText = effectiveStory?.transcript(for: env.settings.audioLanguage) ?? "No transcription available."
            let lines = parseTranscriptLines(transcriptText)
            let activeLineIndex = min(Int(effectiveProgress * Double(max(1, lines.count))), max(0, lines.count - 1))

            ZStack {
                Color(red: 255/255, green: 102/255, blue: 52/255) // #FF6634 Coral
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 1. Top Header Row (Site Title + District + Dismiss Chevron Down)
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(site?.name ?? "Cultural Site")
                                .font(.custom(AppTextStyle.customFontPostScriptName, size: 24))
                                .foregroundStyle(Color.white)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(district)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundStyle(Color.white.opacity(0.9))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Button {
                            dismiss()
                        } label: {
                            AppIcon(.chevronDown, size: 28)
                                .foregroundStyle(Color.white)
                                .frame(width: 36, height: 36)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Dismiss transcript")
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 12)

                    // 2. Karaoke Highlighted Transcript Reader
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 20) {
                                ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                                    if index == activeLineIndex {
                                        // Active highlighted pill
                                        Text(line)
                                            .font(.system(size: 22, weight: .bold))
                                            .foregroundStyle(Color(red: 255/255, green: 102/255, blue: 52/255))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 6)
                                            .background(Color.white)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .id(index)
                                    } else {
                                        // Surrounding inactive lines
                                        Text(line)
                                            .font(.system(size: 22, weight: .regular))
                                            .foregroundStyle(Color(red: 255/255, green: 218/255, blue: 206/255)) // #FFDACE
                                            .id(index)
                                    }
                                }

                                // Attribution Link
                                HStack {
                                    Text("Sources from \(Text("here!").font(.system(size: 16, weight: .semibold)).underline())")
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundStyle(Color.white)
                                    Spacer()
                                }
                                .padding(.top, 12)
                                .padding(.bottom, 24)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                        }
                        .onChange(of: activeLineIndex) { _, newIndex in
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(newIndex, anchor: .center)
                            }
                        }
                    }

                    // 3. Tactile Audio Scrubber Component (Orange Theme)
                    AudioScrubber(
                        progress: Binding(
                            get: { effectiveProgress },
                            set: { newProgress in
                                env.audio.seek(toProgress: newProgress)
                            }
                        ),
                        durationSeconds: duration,
                        theme: .orange,
                        isInteractive: true,
                        onSeek: { seconds in
                            env.audio.seek(toProgress: seconds / duration)
                        }
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)

                    // 4. Audio Control Toolbar (SVG AppIcons in Coral Theme)
                    HStack(spacing: 36) {
                        // Rewind 10s
                        Button {
                            let newProgress = max(0, effectiveProgress - (10.0 / duration))
                            env.audio.seek(toProgress: newProgress)
                        } label: {
                            AppIcon(.rewind10, size: 36)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Rewind 10 seconds")

                        // Primary Chunky Play/Pause Button (60x60 Orange Theme)
                        Button {
                            if isPlaying {
                                env.audio.pause()
                            } else if env.audio.currentStory?.slug == effectiveStory?.slug {
                                env.audio.resume()
                            } else if let effectiveStory {
                                env.audio.play(story: effectiveStory)
                            }
                        } label: {
                            AppIcon(isPlaying ? .pauseOrange : .playOrange, size: 60)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(isPlaying ? "Pause" : "Play")

                        // Forward 10s
                        Button {
                            let newProgress = min(1.0, effectiveProgress + (10.0 / duration))
                            env.audio.seek(toProgress: newProgress)
                        } label: {
                            AppIcon(.forward10, size: 36)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Forward 10 seconds")
                    }
                    .padding(.bottom, 28)
                }
            }
        }
    }

    private func parseTranscriptLines(_ text: String) -> [String] {
        let raw = text.components(separatedBy: CharacterSet(charactersIn: ".\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return raw.isEmpty ? [text] : raw
    }
}

// MARK: - Story Queue Sheet (Figma Node 210:1078)

private struct StoryQueueSheet: View {
    let currentStory: Story?
    let activeSiteName: String
    let remainingTime: Double
    let isPlaying: Bool
    let queueItems: [QueuedStory]
    let onTogglePlayback: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Header Row (Queue Title + Close X)
            HStack {
                Text("Queue")
                    .font(.custom(AppTextStyle.customFontPostScriptName, size: 22))
                    .foregroundStyle(Color(red: 104/255, green: 104/255, blue: 102/255))

                Spacer()

                Button(action: onClose) {
                    AppIcon(.close, size: 20)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close queue")
            }
            .padding(.horizontal, AppSpacing.xs)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // 1. Now Playing Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Now Playing")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(AppColor.Brand.primary) // #1D52D8

                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(activeSiteName)
                                    .font(.custom(AppTextStyle.customFontPostScriptName, size: 20))
                                    .foregroundStyle(AppColor.Brand.primary) // #1D52D8
                                    .lineLimit(1)

                                Text("-\(formatTime(max(0, remainingTime)))")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundStyle(Color(red: 104/255, green: 104/255, blue: 102/255))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            // 40x40 Mini Play/Pause button
                            Button(action: onTogglePlayback) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(AppColor.Brand.primary)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .strokeBorder(Color(red: 17/255, green: 49/255, blue: 130/255), lineWidth: 2.67)
                                        )
                                        .frame(width: 40, height: 40)

                                    if isPlaying {
                                        HStack(spacing: 4) {
                                            Rectangle()
                                                .fill(Color.white)
                                                .frame(width: 4.5, height: 14)
                                                .border(Color(red: 17/255, green: 49/255, blue: 130/255), width: 1.5)
                                            Rectangle()
                                                .fill(Color.white)
                                                .frame(width: 4.5, height: 14)
                                                .border(Color(red: 17/255, green: 49/255, blue: 130/255), width: 1.5)
                                        }
                                    } else {
                                        Image(systemName: "play.fill")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundStyle(Color.white)
                                            .offset(x: 1)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(isPlaying ? "Pause" : "Play")
                        }
                    }

                    // 2. Next Stops Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Next stops:")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(Color(red: 104/255, green: 104/255, blue: 102/255))

                        if queueItems.isEmpty {
                            VStack(spacing: 6) {
                                Text("No upcoming stops queued.")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color(red: 104/255, green: 104/255, blue: 102/255))
                                Text("Stories triggered while wandering will appear here.")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundStyle(Color(red: 140/255, green: 140/255, blue: 138/255))
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                        } else {
                            ForEach(Array(queueItems.enumerated()), id: \.element.id) { _, item in
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.siteName)
                                            .font(.custom(AppTextStyle.customFontPostScriptName, size: 18))
                                            .foregroundStyle(Color(red: 104/255, green: 104/255, blue: 102/255))
                                            .lineLimit(1)

                                        Text(item.storyTitle)
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundStyle(Color(red: 140/255, green: 140/255, blue: 138/255))
                                            .lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                    AppIcon(.slideHandle, size: 28)
                                }
                                .padding(.vertical, 6)
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: 320)
        }
        .padding(18)
        .frame(width: 356)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(Color(red: 231/255, green: 231/255, blue: 231/255), lineWidth: 4) // #E7E7E7
        )
        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
    }

    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && seconds >= 0 else { return "0:00" }
        let total = Int(seconds)
        let mins = total / 60
        let secs = total % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - Previews

#Preview("Sites Player") {
    let env = AppEnvironment()
    SitesPlayerView()
        .environment(env)
}
