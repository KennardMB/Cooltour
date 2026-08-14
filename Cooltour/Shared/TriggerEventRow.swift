import SwiftUI

struct TriggerEventRow: View {
  let event: TriggerEvent

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(event.storyTitle)
          .font(.headline)
        Spacer()
        if event.wasBackground {
          Image(systemName: "moon.fill")
            .foregroundStyle(.purple)
            .accessibilityLabel("Fired in the background")
        }
      }
      Text(event.siteName)
        .font(.subheadline)
      
      Text(event.firedAt.formatted(date: .omitted, time: .shortened))
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .padding(.vertical, 4)
  }
}
