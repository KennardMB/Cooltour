import SwiftUI

// MARK: - Edit Profile Modal Component

public struct EditProfileModal: View {
    @Binding public var isPresented: Bool
    @Binding public var name: String
    @Binding public var status: String
    public let onSave: (String, String) -> Void

    @State private var draftName: String
    @State private var draftStatus: String
    private let maxNameCharacters: Int = 20
    private let maxStatusCharacters: Int = 50

    public init(
        isPresented: Binding<Bool>,
        name: Binding<String>,
        status: Binding<String>,
        onSave: @escaping (String, String) -> Void
    ) {
        self._isPresented = isPresented
        self._name = name
        self._status = status
        self.onSave = onSave
        self._draftName = State(initialValue: name.wrappedValue)
        self._draftStatus = State(initialValue: status.wrappedValue)
    }

    public var body: some View {
        ZStack {
            // Dimmed backdrop
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            // Modal Card Dialog
            VStack(alignment: .leading, spacing: 16) {
                // Modal Header
                Text("Edit Profile")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(AppColor.Text.primary)

                // 1. Profile Name Field (Max 20 chars)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Profile Name")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppColor.Text.secondary)

                    VStack(alignment: .trailing, spacing: 4) {
                        ZStack(alignment: .leading) {
                            if draftName.isEmpty {
                                Text("Enter your name...")
                                    .font(.custom(AppTextStyle.customFontPostScriptName, size: 20))
                                    .foregroundStyle(Color(red: 160/255, green: 160/255, blue: 160/255))
                                    .padding(.horizontal, 4)
                            }

                            TextField("", text: $draftName)
                                .font(.custom(AppTextStyle.customFontPostScriptName, size: 20))
                                .foregroundStyle(AppColor.Text.primary)
                                .padding(.horizontal, 4)
                                .onChange(of: draftName) { _, newValue in
                                    if newValue.count > maxNameCharacters {
                                        draftName = String(newValue.prefix(maxNameCharacters))
                                    }
                                }
                        }
                        .frame(height: 36, alignment: .leading)

                        // Character Count Indicator
                        Text("\(draftName.count)/\(maxNameCharacters)")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(AppColor.Text.secondary)
                    }
                    .padding(10)
                    .background(AppColor.Background.pure)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.standard))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.standard)
                            .strokeBorder(AppColor.Background.border, lineWidth: 1.5)
                    )
                }

                // 2. Status Profile Field (Max 50 chars, "i have..." placeholder)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Status")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppColor.Text.secondary)

                    VStack(alignment: .trailing, spacing: 4) {
                        ZStack(alignment: .topLeading) {
                            if draftStatus.isEmpty {
                                Text("i have...")
                                    .font(.custom(AppTextStyle.customFontPostScriptName, size: 18))
                                    .foregroundStyle(Color(red: 160/255, green: 160/255, blue: 160/255))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 4)
                            }

                            TextField("", text: $draftStatus, axis: .vertical)
                                .font(.custom(AppTextStyle.customFontPostScriptName, size: 18))
                                .foregroundStyle(AppColor.Text.primary)
                                .lineLimit(2)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 4)
                                .onChange(of: draftStatus) { _, newValue in
                                    if newValue.count > maxStatusCharacters {
                                        draftStatus = String(newValue.prefix(maxStatusCharacters))
                                    }
                                }
                        }
                        .frame(minHeight: 56, alignment: .topLeading)

                        // Character Count Indicator
                        Text("\(draftStatus.count)/\(maxStatusCharacters)")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(AppColor.Text.secondary)
                    }
                    .padding(10)
                    .background(AppColor.Background.pure)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.standard))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.standard)
                            .strokeBorder(AppColor.Background.border, lineWidth: 1.5)
                    )
                }

                // 3. Action Buttons (Cancel / Save)
                HStack(spacing: 12) {
                    // Cancel Button (Coral / Destructive)
                    Button {
                        isPresented = false
                    } label: {
                        Text("cancel")
                            .font(.custom(AppTextStyle.customFontPostScriptName, size: 18))
                            .foregroundStyle(AppColor.Background.pure)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color(red: 255/255, green: 102/255, blue: 52/255)) // #FF6634
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.standard))
                    }
                    .buttonStyle(.plain)

                    // Save Button (Blue / Primary)
                    Button {
                        let finalName = draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Anton B." : draftName
                        let finalStatus = draftStatus.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "I have ..." : draftStatus
                        name = finalName
                        status = finalStatus
                        onSave(finalName, finalStatus)
                        isPresented = false
                    } label: {
                        Text("save")
                            .font(.custom(AppTextStyle.customFontPostScriptName, size: 18))
                            .foregroundStyle(AppColor.Background.pure)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(AppColor.Brand.primary) // #1D52D8
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.standard))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
            .padding(20)
            .background(AppColor.Background.pure)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.standard))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.standard)
                    .strokeBorder(AppColor.Background.border, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.18), radius: 16, x: 0, y: 8)
            .padding(.horizontal, 24)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}

// MARK: - Previews

#Preview("Edit Profile Modal") {
    @Previewable @State var isPresented = true
    @Previewable @State var name = "Anton B."
    @Previewable @State var status = "I have ..."

    EditProfileModal(
        isPresented: $isPresented,
        name: $name,
        status: $status,
        onSave: { _, _ in }
    )
}
