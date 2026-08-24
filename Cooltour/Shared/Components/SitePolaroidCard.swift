import SwiftUI

// MARK: - Site Polaroid Card Component

public struct SitePolaroidCard: View {
    public let siteName: String
    public let imageAssetName: String?
    public let width: CGFloat

    public init(siteName: String, imageAssetName: String? = nil, width: CGFloat = 140) {
        self.siteName = siteName
        self.imageAssetName = imageAssetName
        self.width = width
    }

    public var body: some View {
        VStack(spacing: 8) {
            // Photo Area
            ZStack {
                if let image = loadSiteImage() {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    // Placeholder cultural patterned backdrop
                    ZStack {
                        AppColor.Brand.tint
                        VStack(spacing: 4) {
                            AppIcon(.placeVisited, size: 32)
                            Text(siteName)
                                .appFont(.label, color: AppColor.Brand.primary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 4)
                        }
                    }
                }
            }
            .frame(width: width - 16, height: width - 16)
            .clipped()

            // Handwritten-style Caption
            Text(siteName)
                .font(.custom(AppTextStyle.customFontPostScriptName, size: 12))
                .foregroundStyle(AppColor.Text.primary)
                .lineLimit(1)
                .padding(.horizontal, 4)
                .padding(.bottom, 6)
        }
        .padding(.top, 8)
        .padding(.horizontal, 8)
        .padding(.bottom, 2)
        .background(AppColor.Background.pure)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .shadow(color: Color.black.opacity(0.14), radius: 6, x: 0, y: 3)
    }

    private func loadSiteImage() -> UIImage? {
        guard let name = imageAssetName, !name.isEmpty else {
            return nil
        }
        // 1. Try Assets.xcassets
        if let img = UIImage(named: name) {
            return img
        }
        // 2. Try bundled SitePictures folder
        if let path = Bundle.main.path(forResource: name, ofType: nil, inDirectory: "SitePictures"),
           let img = UIImage(contentsOfFile: path) {
            return img
        }
        // 3. Try direct resource path
        let baseName = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension.isEmpty ? "jpg" : (name as NSString).pathExtension
        if let url = Bundle.main.url(forResource: baseName, withExtension: ext),
           let data = try? Data(contentsOf: url),
           let img = UIImage(data: data) {
            return img
        }
        return nil
    }
}

// MARK: - Polaroid Collage View (Overlapping Photos Stack)

public struct SitePolaroidCollage: View {
    public let sites: [(name: String, imageAssetName: String?)]

    public init(sites: [(name: String, imageAssetName: String?)]) {
        self.sites = sites
    }

    public var body: some View {
        ZStack {
            if sites.isEmpty {
                SitePolaroidCard(siteName: "Denpasar Heritage", imageAssetName: "pura-jagatnatha.jpg", width: 150)
            } else if sites.count == 1 {
                SitePolaroidCard(siteName: sites[0].name, imageAssetName: sites[0].imageAssetName, width: 160)
            } else if sites.count == 2 {
                HStack(spacing: -24) {
                    SitePolaroidCard(siteName: sites[0].name, imageAssetName: sites[0].imageAssetName, width: 140)
                        .rotationEffect(.degrees(-6))

                    SitePolaroidCard(siteName: sites[1].name, imageAssetName: sites[1].imageAssetName, width: 150)
                        .rotationEffect(.degrees(5))
                        .zIndex(1)
                }
            } else {
                // 3 or more polaroids in artistic staggered layout per Figma 204:2091
                ZStack {
                    // Left back
                    SitePolaroidCard(siteName: sites[0].name, imageAssetName: sites[0].imageAssetName, width: 135)
                        .rotationEffect(.degrees(-8))
                        .offset(x: -68, y: -10)

                    // Right back
                    SitePolaroidCard(siteName: sites[min(2, sites.count - 1)].name, imageAssetName: sites[min(2, sites.count - 1)].imageAssetName, width: 135)
                        .rotationEffect(.degrees(7))
                        .offset(x: 68, y: 15)

                    // Center foreground
                    SitePolaroidCard(siteName: sites[1].name, imageAssetName: sites[1].imageAssetName, width: 150)
                        .rotationEffect(.degrees(-1))
                        .offset(x: 0, y: -5)
                        .zIndex(2)
                }
                .frame(height: 200)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
    }
}

// MARK: - Previews

#Preview("Polaroid Collage") {
    VStack(spacing: 20) {
        SitePolaroidCollage(sites: [
            ("Pasar Kumbasari", "pasar-kumbasari.jpg"),
            ("Pasar Badung", "pasar-badung.jpg"),
            ("Nadhi Heritage", "nadhi-heritage.jpg")
        ])
    }
    .padding(20)
    .background(AppColor.Background.canvas)
}
