import SwiftUI

/// Playback-speed picker as a row of chips. Kept free of `SettingsStore`/`AudioPlayerService`
/// so it's reusable anywhere a speed needs picking — the call site owns what "select" means.
struct SpeedChips: View {
  let speeds: [Double]
  let selected: Double
  let onSelect: (Double) -> Void

  var body: some View {
    HStack(spacing: 8) {
      ForEach(speeds, id: \.self) { speed in
        let isSelected = speed == selected
        Button {
          onSelect(speed)
        } label: {
          Text("\(speed.formatted())×")
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
              isSelected ? Color.accentColor : Color.gray.opacity(0.15)
            )
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(speed.formatted())× speed")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
      }
    }
  }
}

#Preview {
  SpeedChips(speeds: [0.75, 1.0, 1.25, 1.5], selected: 1.0) { _ in }
    .padding()
}
