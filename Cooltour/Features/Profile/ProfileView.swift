import SwiftUI
import UIKit

// MARK: - Profile View (Figma Node 202:1329)

public struct ProfileView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(AppEnvironment.self) private var env
  
  @AppStorage("has_completed_onboarding") private var hasCompletedOnboarding: Bool = false
  @AppStorage("user_profile_name") private var userName: String = "Anton B."
  @AppStorage("user_profile_status") private var profileStatus: String = "I have ..."
  
  private var userInitial: String {
    let trimmed = userName.trimmingCharacters(in: .whitespaces)
    return String(trimmed.prefix(1)).uppercased()
  }
  @State private var placesVisitedCount: Int = 11
  @State private var distanceKm: Double = 7.7
  @State private var isEditingProfile: Bool = false
  @State private var showSettings: Bool = false
  @State private var showExplorations: Bool = false
  
  // Exhibition reset tap counter state
  @State private var avatarTapCount: Int = 0
  @State private var lastAvatarTapTime: Date = .distantPast
  
  public init() {}
  
  public var body: some View {
    NavigationStack {
      ZStack {
        VStack(alignment: .leading, spacing: 0) {
          // Top Navigation Bar (Back Button)
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
          }
          .padding(.horizontal, AppSpacing.lg)
          .padding(.top, AppSpacing.sm)
          
          ScrollView {
            VStack(alignment: .leading, spacing: 24) {
              // 1. User Header Section
              HStack(spacing: 20) {
                // 80x80 Avatar Box (Brush stroke style - 4 taps triggers exhibition reset)
                ZStack {
                  Image("BrushProfileAvatar")
                    .resizable()
                    .frame(width: 80, height: 80)
                  
                  Text(userInitial)
                    .font(.custom("Baru Lagi", size: 32))
                    .foregroundStyle(Color(red: 29/255, green: 82/255, blue: 216/255)) // #1D52D8
                }
                .frame(width: 80, height: 80)
                .contentShape(Rectangle())
                .onTapGesture {
                  handleAvatarTap()
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Profile avatar")
                .accessibilityHint("Tap 4 times to reset app state for exhibition")
                
                // Name and Subtitle Column
                VStack(alignment: .leading, spacing: 4) {
                  Text("My Profile...")
                    .appFont(.captionL, color: AppColor.Text.primary)
                  
                  HStack(spacing: AppSpacing.sm) {
                    Text(userName)
                      .appFont(.heading1, color: AppColor.Text.primary)
                      .lineLimit(1)
                    
                    Button {
                      isEditingProfile = true
                    } label: {
                      Image(systemName: "pencil")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppColor.Text.primary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Edit profile")
                  }
                }
                
                Spacer()
              }
              .padding(.top, AppSpacing.md)
              
              // 2. Status Section ("I have ...")
              VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack {
                  Text(profileStatus)
                    .appFont(.heading3, color: AppColor.Brand.primary)
                  
                  Spacer()
                  
                  Button {
                    isEditingProfile = true
                  } label: {
                    Image(systemName: "pencil")
                      .font(.system(size: 14, weight: .regular))
                      .foregroundStyle(AppColor.Brand.primary)
                  }
                  .buttonStyle(.plain)
                  .accessibilityLabel("Edit status")
                }
                
                // Exploration Stats Badges (Tall Orange Places Visited + Pink Distances)
                ExplorationSummaryStats(
                  placesVisitedCount: placesVisitedCount,
                  distanceKm: distanceKm,
                  layout: .tall
                )
              }
              .padding(.top, AppSpacing.sm)
              
              // 3. Navigation List Buttons (My Explorations, Settings)
              VStack(spacing: AppSpacing.md) {
                // My Explorations
                Button {
                  showExplorations = true
                } label: {
                  ProfileMenuRow(title: "My explorations")
                }
                .buttonStyle(.plain)
                
                // Settings
                Button {
                  showSettings = true
                } label: {
                  ProfileMenuRow(title: "Settings")
                }
                .buttonStyle(.plain)
              }
              .padding(.top, AppSpacing.md)
              
              Spacer(minLength: 40)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.sm)
          }
        }
        .defaultTiledBackground(scale: 0.20)
        
        // 4. Custom Edit Profile Modal (Figma-styled dialog)
        if isEditingProfile {
          EditProfileModal(
            isPresented: $isEditingProfile,
            name: $userName,
            status: $profileStatus,
            onSave: { newName, newStatus in
              userName = newName
              profileStatus = newStatus
            }
          )
        }
      }
      .navigationBarBackButtonHidden(true)
      .toolbar(.hidden, for: .navigationBar)
      .navigationDestination(isPresented: $showExplorations) {
        MyExplorationsView()
      }
      .navigationDestination(isPresented: $showSettings) {
        SettingsView()
      }
    }
  }

  // MARK: - Exhibition Reset State (4 Taps on Avatar)

  private func handleAvatarTap() {
    let now = Date()
    if now.timeIntervalSince(lastAvatarTapTime) > 2.0 {
      avatarTapCount = 1
    } else {
      avatarTapCount += 1
    }
    lastAvatarTapTime = now

    // Tactile feedback on each tap
    UIImpactFeedbackGenerator(style: .light).impactOccurred()

    if avatarTapCount >= 4 {
      avatarTapCount = 0
      UINotificationFeedbackGenerator().notificationOccurred(.success)
      resetAppStateForExhibition()
    }
  }

  private func resetAppStateForExhibition() {
    // 1. Reset onboarding completion so RootView switches back to OnboardingFlowView
    hasCompletedOnboarding = false
    UserDefaults.standard.set(false, forKey: "has_completed_onboarding")

    // 2. Reset user profile defaults
    userName = "Anton B."
    profileStatus = "I have ..."
    UserDefaults.standard.set("Anton B.", forKey: "user_profile_name")
    UserDefaults.standard.set("I have ...", forKey: "user_profile_status")

    // 3. Stop active audio, cancel pending narration prompts & clear playlist
    env.audio.stop()
    env.narration.cancelSession()
    env.playlist.clear()

    // 4. Reset walking mode and stop proximity listening
    env.settings.walkingMode = false
    UserDefaults.standard.set(false, forKey: AppConfig.walkingModeKey)
    env.proximity.stop()

    // 5. Clear all walk history & trigger events
    env.history.stopWalk()
    env.history.deleteAllWalks()

    // 6. Dismiss profile modal
    dismiss()
  }
}

// MARK: - Profile Menu Row Component (Brush-stroke row button)

private struct ProfileMenuRow: View {
  let title: String
  
  var body: some View {
    ZStack {
      Image("BrushRowButton")
        .resizable()
        .frame(height: 60)
        .frame(maxWidth: .infinity)
      
      HStack {
        Text(title)
          .font(.custom("Baru Lagi", size: 16))
          .foregroundStyle(Color(red: 104/255, green: 104/255, blue: 102/255)) // #686866
        
        Spacer()
        
        AppIcon(.chevronRight, size: 20)
          .foregroundStyle(Color(red: 104/255, green: 104/255, blue: 102/255))
      }
      .padding(.horizontal, 20)
    }
    .frame(maxWidth: .infinity)
    .frame(height: 60)
  }
}

// MARK: - Previews

#Preview("Profile Screen") {
  ProfileView()
    .environment(AppEnvironment())
}
