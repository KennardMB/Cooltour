import SwiftUI

// MARK: - Edit Exploration Modal Component (Figma Node 204:2356)

public struct EditExplorationModal: View {
  @Binding public var isPresented: Bool
  @Binding public var title: String
  @Binding public var theme: CulturalColorTheme
  public let onSave: (String, CulturalColorTheme) -> Void
  
  @State private var draftTitle: String
  @State private var draftTheme: CulturalColorTheme
  private let maxCharacters: Int = 50
  
  public init(
    isPresented: Binding<Bool>,
    title: Binding<String>,
    theme: Binding<CulturalColorTheme>,
    onSave: @escaping (String, CulturalColorTheme) -> Void
  ) {
    self._isPresented = isPresented
    self._title = title
    self._theme = theme
    self.onSave = onSave
    self._draftTitle = State(initialValue: title.wrappedValue)
    self._draftTheme = State(initialValue: theme.wrappedValue)
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
        Text("Edit Exploration")
          .font(.system(size: 15, weight: .regular))
          .foregroundStyle(AppColor.Text.primary)
        
        // Editable Title Text Area (50 chars limit)
        VStack(alignment: .trailing, spacing: 6) {
          ZStack(alignment: .topLeading) {
            if draftTitle.isEmpty {
              Text("Title goes here...")
                .font(.custom(AppTextStyle.customFontPostScriptName, size: 20))
                .foregroundStyle(Color(red: 160/255, green: 160/255, blue: 160/255))
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
            }
            
            TextField("", text: $draftTitle, axis: .vertical)
              .font(.custom(AppTextStyle.customFontPostScriptName, size: 20))
              .foregroundStyle(AppColor.Text.primary)
              .lineLimit(3)
              .padding(.horizontal, 4)
              .padding(.vertical, 4)
              .onChange(of: draftTitle) { _, newValue in
                if newValue.count > maxCharacters {
                  draftTitle = String(newValue.prefix(maxCharacters))
                }
              }
          }
          .frame(minHeight: 90, alignment: .topLeading)
          
          // Character Count Indicator
          Text("\(draftTitle.count)/\(maxCharacters)")
            .font(.system(size: 12, weight: .regular))
            .foregroundStyle(AppColor.Text.secondary)
        }
        .padding(12)
        .background(AppColor.Background.pure)
        .overlay(
          RoundedRectangle(cornerRadius: AppRadius.standard)
            .strokeBorder(AppColor.Background.border, lineWidth: 1.5)
        )
        
        // Color Theme Selector
        HStack(spacing: 14) {
          ForEach(CulturalColorTheme.allCases) { colorTheme in
            Button {
              draftTheme = colorTheme
            } label: {
              ZStack {
                Circle()
                  .fill(colorTheme.color)
                  .frame(width: 32, height: 32)
                
                if draftTheme == colorTheme {
                  AppIcon(.check, size: 16)
                }
              }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Select \(colorTheme.rawValue) theme")
          }
        }
        .padding(.vertical, 4)
        
        // Action Buttons (Cancel / Save)
        HStack(spacing: 12) {
          // Cancel Button (Orange / Destructive)
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
            let finalTitle = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Exploration walk" : draftTitle
            title = finalTitle
            theme = draftTheme
            onSave(finalTitle, draftTheme)
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
    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPresented)
  }
}

// MARK: - Previews

#Preview("Edit Exploration Modal") {
  ZStack {
    Color.gray.opacity(0.2).ignoresSafeArea()
    
    EditExplorationModal(
      isPresented: .constant(true),
      title: .constant("sabtu sama kean tami nanda nisa shin ke gajah mada"),
      theme: .constant(.blue),
      onSave: { _, _ in }
    )
  }
}
