import CoreLocation
import SwiftUI

// MARK: - Settings View (Figma Node 231:1666)

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var env
    @AppStorage("auto_play_nearby_stories") private var autoPlayNearby: Bool = true

    var body: some View {
        @Bindable var settings = env.settings

        VStack(alignment: .leading, spacing: 0) {
            // 1. Top Navigation Bar
            HStack {
                Button {
                    dismiss()
                } label: {
                    AppIcon(.chevronLeft, size: 24)
                        .padding(AppSpacing.sm)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")

                Spacer()

                Text("Settings")
                    .font(.custom("Baru Lagi", size: 20))
                    .foregroundStyle(Color(red: 17/255, green: 17/255, blue: 17/255))

                Spacer()

                // Balance layout spacing
                Color.clear
                    .frame(width: 32, height: 32)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)

            // 2. Settings Content List
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Section 1: Background
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Background")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(Color(red: 117/255, green: 117/255, blue: 117/255))
                            .padding(.leading, 4)

                        VStack(spacing: 0) {
                            // Toggle Row
                            HStack {
                                Text("Background triggering")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundStyle(Color(red: 29/255, green: 82/255, blue: 216/255))

                                Spacer()

                                Toggle("", isOn: $settings.walkingMode)
                                    .labelsHidden()
                                    .tint(Color(red: 29/255, green: 82/255, blue: 216/255))
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 46)

                            Divider()
                                .background(Color(red: 226/255, green: 225/255, blue: 222/255))

                            // Location Access Row
                            HStack {
                                Text("Location access")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundStyle(Color(red: 29/255, green: 82/255, blue: 216/255))

                                Spacer()

                                Text(env.proximity.authorizationStatus.displayName)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundStyle(Color(red: 117/255, green: 117/255, blue: 117/255))
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 46)
                        }
                        .background(
                            Image("BrushCard")
                                .resizable()
                        )

                        Text(walkingModeFooter)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(Color(red: 117/255, green: 117/255, blue: 117/255))
                            .padding(.horizontal, 4)
                            .padding(.top, 2)
                    }

                    // Section 2: Language (from main — EN/ID app + story audio)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Language")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(Color(red: 117/255, green: 117/255, blue: 117/255))
                            .padding(.leading, 4)

                        VStack(spacing: 0) {
                            HStack {
                                Text("App language")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundStyle(Color(red: 29/255, green: 82/255, blue: 216/255))

                                Spacer()

                                Menu {
                                    ForEach(AppLanguagePreference.allCases) { preference in
                                        Button {
                                            settings.appLanguage = preference
                                        } label: {
                                            HStack {
                                                Text(preference.displayName)
                                                if settings.appLanguage == preference {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    settingsValueLabel(settings.appLanguage.displayName)
                                }
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 46)

                            Divider()
                                .background(Color(red: 226/255, green: 225/255, blue: 222/255))

                            HStack {
                                Text("Story audio")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundStyle(Color(red: 29/255, green: 82/255, blue: 216/255))

                                Spacer()

                                Menu {
                                    ForEach(AudioLanguagePreference.allCases) { preference in
                                        Button {
                                            settings.audioLanguage = preference
                                            if let currentStory = env.audio.currentStory {
                                                let wasPlaying = env.audio.isPlaying
                                                env.audio.play(story: currentStory)
                                                if !wasPlaying {
                                                    env.audio.pause()
                                                }
                                            }
                                        } label: {
                                            HStack {
                                                Text(preference.displayName)
                                                if settings.audioLanguage == preference {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    settingsValueLabel(settings.audioLanguage.displayName)
                                }
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 46)
                        }
                        .background(
                            Image("BrushCard")
                                .resizable()
                        )

                        VStack(alignment: .leading, spacing: 8) {
                            Text(String(localized: "language.app.footer"))
                            if settings.audioLanguage == .indonesian {
                                Text(String(localized: "language.audio.indonesian_footer"))
                            }
                        }
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color(red: 117/255, green: 117/255, blue: 117/255))
                        .padding(.horizontal, 4)
                        .padding(.top, 2)
                    }

                    // Section 3: Playback
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Playback")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(Color(red: 117/255, green: 117/255, blue: 117/255))
                            .padding(.leading, 4)

                        VStack(spacing: 0) {
                            // Auto-play Toggle
                            HStack {
                                Text("Auto-play nearby stories")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundStyle(Color(red: 29/255, green: 82/255, blue: 216/255))

                                Spacer()

                                Toggle("", isOn: $autoPlayNearby)
                                    .labelsHidden()
                                    .tint(Color(red: 29/255, green: 82/255, blue: 216/255))
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 46)

                            Divider()
                                .background(Color(red: 226/255, green: 225/255, blue: 222/255))

                            // Default Speed Menu
                            HStack {
                                Text("Default speed")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundStyle(Color(red: 29/255, green: 82/255, blue: 216/255))

                                Spacer()

                                Menu {
                                    ForEach(SettingsStore.availablePlaybackSpeeds, id: \.self) { speed in
                                        Button {
                                            settings.defaultPlaybackSpeed = speed
                                            env.audio.setRate(Float(speed))
                                        } label: {
                                            HStack {
                                                Text("\(speed.formatted())×")
                                                if settings.defaultPlaybackSpeed == speed {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    settingsValueLabel("\(settings.defaultPlaybackSpeed.formatted())x")
                                }
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 46)
                        }
                        .background(
                            Image("BrushCard")
                                .resizable()
                        )
                    }

                    // Section 3: Permissions
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Permissions")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(Color(red: 117/255, green: 117/255, blue: 117/255))
                            .padding(.leading, 4)

                        VStack(spacing: 0) {
                            // Notifications Status / Request Button
                            Button {
                                if !env.notifications.isAuthorized {
                                    Task {
                                        _ = await env.notifications.requestAuthorization()
                                    }
                                }
                            } label: {
                                HStack {
                                    Text("Notifications")
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundStyle(Color(red: 29/255, green: 82/255, blue: 216/255))

                                    Spacer()

                                    Text(env.notifications.isAuthorized ? "Allowed" : "Not requested")
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundStyle(Color(red: 117/255, green: 117/255, blue: 117/255))
                                }
                                .padding(.horizontal, 14)
                                .frame(height: 46)
                            }
                            .buttonStyle(.plain)

                            Divider()
                                .background(Color(red: 226/255, green: 225/255, blue: 222/255))

                            // Open System Settings Button
                            Button {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                HStack {
                                    Text("Open System Settings")
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundStyle(Color(red: 29/255, green: 82/255, blue: 216/255))

                                    Spacer()

                                    Image(systemName: "arrow.up.forward.app")
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundStyle(Color(red: 117/255, green: 117/255, blue: 117/255))
                                }
                                .padding(.horizontal, 14)
                                .frame(height: 46)
                            }
                            .buttonStyle(.plain)
                        }
                        .background(
                            Image("BrushCard")
                                .resizable()
                        )
                    }

                    // Section 4: About
                    VStack(alignment: .leading, spacing: 6) {
                        Text("About")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(Color(red: 117/255, green: 117/255, blue: 117/255))
                            .padding(.leading, 4)

                        VStack(spacing: 0) {
                            HStack {
                                Text("App")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundStyle(Color(red: 29/255, green: 82/255, blue: 216/255))

                                Spacer()

                                Text(AppConfig.appName)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundStyle(Color(red: 117/255, green: 117/255, blue: 117/255))
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 46)

                            Divider()
                                .background(Color(red: 226/255, green: 225/255, blue: 222/255))

                            HStack {
                                Text("Downloaded status")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundStyle(Color(red: 29/255, green: 82/255, blue: 216/255))

                                Spacer()

                                Text("Offline ready")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundStyle(Color(red: 117/255, green: 117/255, blue: 117/255))
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 46)

                            Divider()
                                .background(Color(red: 226/255, green: 225/255, blue: 222/255))

                            HStack {
                                Text("Sites loaded")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundStyle(Color(red: 29/255, green: 82/255, blue: 216/255))

                                Spacer()

                                Text("\(env.content.siteCount)")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundStyle(Color(red: 117/255, green: 117/255, blue: 117/255))
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 46)
                        }
                        .background(
                            Image("BrushCard")
                                .resizable()
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .defaultTiledBackground(scale: 0.20)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await env.notifications.refreshAuthorization()
        }
    }

    private func settingsValueLabel(_ text: String) -> some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color(red: 117/255, green: 117/255, blue: 117/255))

            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(red: 117/255, green: 117/255, blue: 117/255))
        }
    }

    /// Says what walking mode will actually do, including when it can't — "Always" is a big ask and
    /// the honest answer to a refusal is that the app still works, just not with the screen off.
    /// Turning walking mode off stops all use of location, but iOS still shows the granted level in
    /// Settings until the user changes it there; it can't be revoked from code.
    private var walkingModeFooter: String {
        guard env.settings.walkingMode else {
            return String(
                format: String(localized: "walking_mode.footer.off"),
                AppConfig.appName
            )
        }
        return switch env.proximity.authorizationStatus {
        case .authorizedAlways:
            String(localized: "walking_mode.footer.always")
        case .authorizedWhenInUse:
            String(localized: "walking_mode.footer.when_in_use")
        case .denied, .restricted:
            String(
                format: String(localized: "walking_mode.footer.denied"),
                AppConfig.appName
            )
        default:
            String(localized: "walking_mode.footer.default")
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView().environment(AppEnvironment())
    }
}
