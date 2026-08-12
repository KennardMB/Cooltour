import SwiftUI

struct NowView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(env.proximity.isListening
                     ? "Listening for nearby stories"
                     : "Not listening")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Button(env.proximity.isListening ? "Stop listening" : "Start listening") {
                    if env.proximity.isListening {
                        env.proximity.stop()
                    } else {
                        env.proximity.start()
                    }
                }
                .buttonStyle(.borderedProminent)

                // Quick Controls Chips (Single source of truth with SettingsStore)
                HStack(spacing: 12) {
                    Button {
                        env.settings.autoPlay.toggle()
                    } label: {
                        Label(
                            env.settings.autoPlay ? "Auto-play ON" : "Auto-play OFF",
                            systemImage: env.settings.autoPlay ? "bolt.fill" : "bolt.slash"
                        )
                        .font(.footnote)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(env.settings.autoPlay ? Color.blue.opacity(0.15) : Color.gray.opacity(0.15))
                        .foregroundStyle(env.settings.autoPlay ? .blue : .secondary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Menu {
                        ForEach(SettingsStore.availablePlaybackSpeeds, id: \.self) { speed in
                            Button("\(speed.formatted())×") {
                                env.settings.defaultPlaybackSpeed = speed
                                env.audio.setRate(Float(speed))
                            }
                        }
                    } label: {
                        Label(
                            "\(env.settings.defaultPlaybackSpeed.formatted())× Speed",
                            systemImage: "speedometer"
                        )
                        .font(.footnote)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.15))
                        .foregroundStyle(.primary)
                        .clipShape(Capsule())
                    }
                }

                Text("\(env.content.siteCount) sites loaded")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
            .navigationTitle("Now")
        }
    }
}

#Preview {
    NowView().environment(AppEnvironment())
}
