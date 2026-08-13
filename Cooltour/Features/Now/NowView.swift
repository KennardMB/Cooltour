import SwiftUI

struct NowView: View {
  @Environment(AppEnvironment.self) private var env

  var body: some View {
    NavigationStack {
      VStack(spacing: 24) {
        Text(
          env.proximity.isListening
            ? "Listening for nearby stories"
            : "Not listening"
        )
        .font(.title3)
        .foregroundStyle(.secondary)

        Button(env.proximity.isListening ? "Stop listening" : "Start listening")
        {
          if env.proximity.isListening {
            env.proximity.stop()
          } else {
            env.proximity.start()
          }
        }
        .buttonStyle(.borderedProminent)

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
