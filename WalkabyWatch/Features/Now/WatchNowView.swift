import SwiftUI

/// Watch Now glance — walking toggle, consent, play-start arrow (Slices 18–21).
struct WatchNowView: View {
  @Bindable var session: WatchSessionClient
  @Bindable var wayfinding: WatchWayfinding

  var body: some View {
    Group {
      if !session.isSessionActivated || (!session.isPhoneReachable && session.snapshot == nil) {
        unavailableView
      } else if let snapshot = session.snapshot {
        content(for: snapshot)
      } else {
        unavailableView
      }
    }
    .padding(.horizontal, 4)
    .onChange(of: session.snapshot?.wayfindingTarget) { _, target in
      wayfinding.updateTarget(target)
    }
  }

  @ViewBuilder
  private func content(for snapshot: WatchSessionSnapshot) -> some View {
    let lang = snapshot.languageCode
    switch snapshot.narrationState {
    case .prompting:
      if let prompt = snapshot.pendingPrompt {
        consentView(prompt: prompt, countdown: snapshot.dismissCountdownSeconds, languageCode: lang)
      } else {
        listeningOrOff(snapshot: snapshot, languageCode: lang)
      }
    case .playing:
      playingView(snapshot: snapshot, languageCode: lang)
    case .idle:
      listeningOrOff(snapshot: snapshot, languageCode: lang)
    }
  }

  private var unavailableView: some View {
    VStack(spacing: 6) {
      Text(AppConfig.appName)
        .font(.headline)
        .accessibilityAddTraits(.isHeader)
      Text(ConsentStrings.statusPhoneRequired(languageCode: "en"))
        .font(.footnote)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .accessibilityElement(children: .combine)
  }

  @ViewBuilder
  private func listeningOrOff(snapshot: WatchSessionSnapshot, languageCode: String) -> some View {
    VStack(spacing: 8) {
      Text(AppConfig.appName)
        .font(.caption2)
        .foregroundStyle(.secondary)

      Text(
        snapshot.walkingModeEnabled
          ? ConsentStrings.statusListening(languageCode: languageCode)
          : ConsentStrings.statusWalkingOff(languageCode: languageCode)
      )
      .font(.headline)
      .multilineTextAlignment(.center)
      .accessibilityAddTraits(.isHeader)

      Toggle(
        ConsentStrings.statusListening(languageCode: languageCode),
        isOn: walkingBinding(snapshot: snapshot)
      )
      .labelsHidden()
      .accessibilityLabel(
        snapshot.walkingModeEnabled
          ? ConsentStrings.statusListening(languageCode: languageCode)
          : ConsentStrings.statusWalkingOff(languageCode: languageCode)
      )
    }
  }

  private func consentView(
    prompt: PendingPrompt,
    countdown: Int?,
    languageCode: String
  ) -> some View {
    VStack(spacing: 6) {
      Text(prompt.siteName)
        .font(.headline)
        .multilineTextAlignment(.center)
        .accessibilityAddTraits(.isHeader)
        .accessibilityLabel(
          ConsentStrings.storyPromptAccessibility(
            siteName: prompt.siteName,
            languageCode: languageCode
          )
        )

      Button(ConsentStrings.playNowAction(languageCode: languageCode)) {
        session.send(.accept(promptID: prompt.id))
      }
      .tint(.green)

      Button(ConsentStrings.addToQueueAction(languageCode: languageCode)) {
        session.send(.queue(promptID: prompt.id))
      }

      Button(dismissLabel(countdown: countdown, languageCode: languageCode)) {
        session.send(.dismiss(promptID: prompt.id))
      }
      .tint(.red)
    }
  }

  private func playingView(snapshot: WatchSessionSnapshot, languageCode: String) -> some View {
    let siteName =
      snapshot.wayfindingTarget?.siteName
      ?? snapshot.nowPlayingSiteName
      ?? ConsentStrings.statusPlayingUnknown(languageCode: languageCode)

    return VStack(spacing: 6) {
      Text(siteName)
        .font(.headline)
        .multilineTextAlignment(.center)
        .accessibilityAddTraits(.isHeader)

      if let rotation = wayfinding.arrowRotationDegrees {
        Image(systemName: "location.north.fill")
          .font(.system(size: 36, weight: .semibold))
          .rotationEffect(.degrees(rotation))
          .accessibilityLabel(
            "\(siteName), \(ArrowAngle.relativeDirectionLabel(rotationDegrees: rotation, languageCode: languageCode))"
          )

        if let meters = wayfinding.distanceMeters {
          Text("\(Int(meters.rounded())) m")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
        }
      } else {
        Text(ConsentStrings.statusPlaying(title: snapshot.nowPlayingStoryTitle ?? siteName, languageCode: languageCode))
          .font(.caption)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }

      Toggle(
        ConsentStrings.statusListening(languageCode: languageCode),
        isOn: walkingBinding(snapshot: snapshot)
      )
      .labelsHidden()
      .accessibilityLabel(ConsentStrings.statusWalkingOff(languageCode: languageCode))
    }
  }

  private func walkingBinding(snapshot: WatchSessionSnapshot) -> Binding<Bool> {
    Binding(
      get: { snapshot.walkingModeEnabled },
      set: { session.setWalkingMode($0) }
    )
  }

  private func dismissLabel(countdown: Int?, languageCode: String) -> String {
    if let countdown, countdown > 0 {
      return ConsentStrings.dismissWithCountdown(countdown, languageCode: languageCode)
    }
    return ConsentStrings.dismissAction(languageCode: languageCode)
  }
}

#Preview {
  WatchNowView(session: WatchSessionClient(), wayfinding: WatchWayfinding())
}
