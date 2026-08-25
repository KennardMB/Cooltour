import SwiftUI

// MARK: - Profile View (Figma Node 202:1329)

public struct ProfileView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(AppEnvironment.self) private var env
  
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
                // 80x80 Avatar Box
                ZStack {
                  RoundedRectangle(cornerRadius: AppRadius.standard)
                    .fill(AppColor.Brand.tint)
                    .frame(width: 80, height: 80)
                    .overlay(
                      RoundedRectangle(cornerRadius: AppRadius.standard)
                        .strokeBorder(AppColor.Brand.primary, lineWidth: AppBorderWidth.standard)
                    )
                  
                  Text(userInitial)
                    .appFont(.heading1, color: AppColor.Brand.primary)
                }
                .accessibilityHidden(true)
                
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
}

// MARK: - Profile Menu Row Component

private struct ProfileMenuRow: View {
  let title: String
  
  var body: some View {
    HStack {
      Text(title)
        .appFont(.heading3, color: AppColor.Background.muted)
      
      Spacer()
      
      AppIcon(.chevronRight, size: 20)
    }
    .padding(.horizontal, AppSpacing.lg)
    .padding(.vertical, AppSpacing.lg)
    .background(AppColor.Background.pure)
    .clipShape(RoundedRectangle(cornerRadius: AppRadius.standard))
    .overlay(
      RoundedRectangle(cornerRadius: AppRadius.standard)
        .strokeBorder(AppColor.Background.muted, lineWidth: AppBorderWidth.standard)
    )
  }
}

// MARK: - Previews

#Preview("Profile Screen") {
  ProfileView()
    .environment(AppEnvironment())
}
