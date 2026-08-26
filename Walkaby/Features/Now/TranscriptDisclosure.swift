import SwiftUI

/// Transcript is the fallback, not the primary path — collapsed by default so audio stays
/// the thing the user actually consumes.
struct TranscriptDisclosure: View {
  let transcript: String
  @State private var isExpanded = false

  var body: some View {
    DisclosureGroup("Transcript", isExpanded: $isExpanded) {
      Text(transcript)
        .font(.callout)
        .foregroundStyle(.primary)
        .padding(.top, 4)
        .accessibilityLabel("Transcript: \(transcript)")
    }
    .font(.subheadline.weight(.medium))
  }
}

#Preview {
  TranscriptDisclosure(
    transcript: "As told by a Kultara guide: this temple has stood since..."
  )
  .padding()
}
