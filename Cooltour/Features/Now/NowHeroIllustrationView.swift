import SwiftUI

// MARK: - Now Hero Illustration Placeholder (Figma Node 223:1344)
/// Hand-drawn doodle illustration showing a traveler walking past cultural sites.
/// Acts as a placeholder ready for replacement with animations in a future slice.
public struct NowHeroIllustrationView: View {
    public init() {}

    public var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let scale = min(w / 360.0, h / 300.0)

            context.stroke(
                drawLeftCloud(scale: scale, origin: CGPoint(x: 20 * scale, y: 30 * scale)),
                with: .color(Color(red: 17/255, green: 17/255, blue: 17/255)),
                lineWidth: 3.0 * scale
            )

            context.stroke(
                drawRightCloud(scale: scale, origin: CGPoint(x: 230 * scale, y: 25 * scale)),
                with: .color(Color(red: 17/255, green: 17/255, blue: 17/255)),
                lineWidth: 3.0 * scale
            )

            // Ground lines
            var groundLine1 = Path()
            groundLine1.move(to: CGPoint(x: 30 * scale, y: 220 * scale))
            groundLine1.addLine(to: CGPoint(x: 160 * scale, y: 218 * scale))
            context.stroke(groundLine1, with: .color(Color(red: 17/255, green: 17/255, blue: 17/255)), lineWidth: 3.0 * scale)

            var groundLine2 = Path()
            groundLine2.move(to: CGPoint(x: 230 * scale, y: 218 * scale))
            groundLine2.addLine(to: CGPoint(x: 340 * scale, y: 220 * scale))
            context.stroke(groundLine2, with: .color(Color(red: 17/255, green: 17/255, blue: 17/255)), lineWidth: 3.0 * scale)

            var baseLine = Path()
            baseLine.move(to: CGPoint(x: 30 * scale, y: 242 * scale))
            baseLine.addCurve(
                to: CGPoint(x: 310 * scale, y: 245 * scale),
                control1: CGPoint(x: 120 * scale, y: 240 * scale),
                control2: CGPoint(x: 220 * scale, y: 242 * scale)
            )
            context.stroke(baseLine, with: .color(Color(red: 17/255, green: 17/255, blue: 17/255)), lineWidth: 3.2 * scale)

            // Left Building (Shrine with cross/dome)
            context.stroke(
                drawLeftBuilding(scale: scale, origin: CGPoint(x: 50 * scale, y: 160 * scale)),
                with: .color(Color(red: 17/255, green: 17/255, blue: 17/255)),
                lineWidth: 2.8 * scale
            )

            // Center Building (Temple with tower and diamonds)
            context.stroke(
                drawCenterBuilding(scale: scale, origin: CGPoint(x: 110 * scale, y: 155 * scale)),
                with: .color(Color(red: 17/255, green: 17/255, blue: 17/255)),
                lineWidth: 2.8 * scale
            )

            // Right Building (Pillared Hall / Candi)
            context.stroke(
                drawRightBuilding(scale: scale, origin: CGPoint(x: 230 * scale, y: 165 * scale)),
                with: .color(Color(red: 17/255, green: 17/255, blue: 17/255)),
                lineWidth: 2.8 * scale
            )

            // Walking Traveler Figure
            context.stroke(
                drawTraveler(scale: scale, origin: CGPoint(x: 175 * scale, y: 185 * scale)),
                with: .color(Color(red: 17/255, green: 17/255, blue: 17/255)),
                lineWidth: 2.8 * scale
            )
        }
        .aspectRatio(360.0 / 280.0, contentMode: .fit)
        .accessibilityLabel("Illustration of a traveler exploring cultural sites")
    }

    // MARK: - Sub-Paths

    private func drawLeftCloud(scale: CGFloat, origin: CGPoint) -> Path {
        var path = Path()
        let ox = origin.x
        let oy = origin.y
        path.move(to: CGPoint(x: ox + 15 * scale, y: oy + 25 * scale))
        path.addQuadCurve(to: CGPoint(x: ox + 45 * scale, y: oy + 5 * scale), control: CGPoint(x: ox + 20 * scale, y: oy))
        path.addQuadCurve(to: CGPoint(x: ox + 95 * scale, y: oy + 10 * scale), control: CGPoint(x: ox + 70 * scale, y: oy - 5 * scale))
        path.addQuadCurve(to: CGPoint(x: ox + 125 * scale, y: oy + 28 * scale), control: CGPoint(x: ox + 115 * scale, y: oy + 12 * scale))
        path.addQuadCurve(to: CGPoint(x: ox + 95 * scale, y: oy + 38 * scale), control: CGPoint(x: ox + 120 * scale, y: oy + 42 * scale))
        path.addQuadCurve(to: CGPoint(x: ox + 65 * scale, y: oy + 30 * scale), control: CGPoint(x: ox + 80 * scale, y: oy + 40 * scale))
        path.addQuadCurve(to: CGPoint(x: ox + 35 * scale, y: oy + 38 * scale), control: CGPoint(x: ox + 50 * scale, y: oy + 42 * scale))
        path.addQuadCurve(to: CGPoint(x: ox + 15 * scale, y: oy + 25 * scale), control: CGPoint(x: ox + 20 * scale, y: oy + 38 * scale))
        return path
    }

    private func drawRightCloud(scale: CGFloat, origin: CGPoint) -> Path {
        var path = Path()
        let ox = origin.x
        let oy = origin.y
        path.move(to: CGPoint(x: ox + 10 * scale, y: oy + 20 * scale))
        path.addQuadCurve(to: CGPoint(x: ox + 35 * scale, y: oy + 5 * scale), control: CGPoint(x: ox + 15 * scale, y: oy))
        path.addQuadCurve(to: CGPoint(x: ox + 75 * scale, y: oy + 8 * scale), control: CGPoint(x: ox + 55 * scale, y: oy - 3 * scale))
        path.addQuadCurve(to: CGPoint(x: ox + 105 * scale, y: oy + 22 * scale), control: CGPoint(x: ox + 95 * scale, y: oy + 10 * scale))
        path.addQuadCurve(to: CGPoint(x: ox + 80 * scale, y: oy + 34 * scale), control: CGPoint(x: ox + 100 * scale, y: oy + 36 * scale))
        path.addQuadCurve(to: CGPoint(x: ox + 50 * scale, y: oy + 26 * scale), control: CGPoint(x: ox + 65 * scale, y: oy + 36 * scale))
        path.addQuadCurve(to: CGPoint(x: ox + 25 * scale, y: oy + 32 * scale), control: CGPoint(x: ox + 35 * scale, y: oy + 36 * scale))
        path.addQuadCurve(to: CGPoint(x: ox + 10 * scale, y: oy + 20 * scale), control: CGPoint(x: ox + 12 * scale, y: oy + 30 * scale))
        return path
    }

    private func drawLeftBuilding(scale: CGFloat, origin: CGPoint) -> Path {
        var path = Path()
        let ox = origin.x
        let oy = origin.y
        // Roof dome & cross
        path.move(to: CGPoint(x: ox + 18 * scale, y: oy - 25 * scale))
        path.addLine(to: CGPoint(x: ox + 18 * scale, y: oy - 40 * scale))
        path.move(to: CGPoint(x: ox + 10 * scale, y: oy - 33 * scale))
        path.addLine(to: CGPoint(x: ox + 26 * scale, y: oy - 33 * scale))

        path.move(to: CGPoint(x: ox, y: oy))
        path.addQuadCurve(to: CGPoint(x: ox + 36 * scale, y: oy), control: CGPoint(x: ox + 18 * scale, y: oy - 25 * scale))
        // Walls
        path.move(to: CGPoint(x: ox + 2 * scale, y: oy))
        path.addLine(to: CGPoint(x: ox + 4 * scale, y: oy + 50 * scale))
        path.move(to: CGPoint(x: ox + 34 * scale, y: oy))
        path.addLine(to: CGPoint(x: ox + 37 * scale, y: oy + 48 * scale))
        // Door
        path.move(to: CGPoint(x: ox + 14 * scale, y: oy + 50 * scale))
        path.addLine(to: CGPoint(x: ox + 14 * scale, y: oy + 25 * scale))
        path.addLine(to: CGPoint(x: ox + 24 * scale, y: oy + 25 * scale))
        path.addLine(to: CGPoint(x: ox + 24 * scale, y: oy + 50 * scale))
        return path
    }

    private func drawCenterBuilding(scale: CGFloat, origin: CGPoint) -> Path {
        var path = Path()
        let ox = origin.x
        let oy = origin.y
        // Tower spire
        path.move(to: CGPoint(x: ox + 25 * scale, y: oy - 48 * scale))
        path.addLine(to: CGPoint(x: ox + 12 * scale, y: oy - 20 * scale))
        path.addLine(to: CGPoint(x: ox + 38 * scale, y: oy - 20 * scale))
        path.closeSubpath()
        // Upper window
        path.addRect(CGRect(x: ox + 20 * scale, y: oy - 16 * scale, width: 10 * scale, height: 10 * scale))

        // Main roof
        path.move(to: CGPoint(x: ox + 5 * scale, y: oy - 4 * scale))
        path.addLine(to: CGPoint(x: ox + 25 * scale, y: oy - 20 * scale))
        path.addLine(to: CGPoint(x: ox + 45 * scale, y: oy - 4 * scale))
        // Walls
        path.move(to: CGPoint(x: ox + 5 * scale, y: oy - 4 * scale))
        path.addLine(to: CGPoint(x: ox + 8 * scale, y: oy + 50 * scale))
        path.move(to: CGPoint(x: ox + 45 * scale, y: oy - 4 * scale))
        path.addLine(to: CGPoint(x: ox + 48 * scale, y: oy + 50 * scale))

        // Diamond decorations
        drawDiamond(into: &path, center: CGPoint(x: ox + 16 * scale, y: oy + 16 * scale), radius: 6 * scale)
        drawDiamond(into: &path, center: CGPoint(x: ox + 36 * scale, y: oy + 16 * scale), radius: 6 * scale)

        // Door
        path.move(to: CGPoint(x: ox + 22 * scale, y: oy + 50 * scale))
        path.addLine(to: CGPoint(x: ox + 22 * scale, y: oy + 32 * scale))
        path.addLine(to: CGPoint(x: ox + 30 * scale, y: oy + 32 * scale))
        path.addLine(to: CGPoint(x: ox + 30 * scale, y: oy + 50 * scale))
        return path
    }

    private func drawRightBuilding(scale: CGFloat, origin: CGPoint) -> Path {
        var path = Path()
        let ox = origin.x
        let oy = origin.y
        // Roof
        path.move(to: CGPoint(x: ox - 4 * scale, y: oy))
        path.addLine(to: CGPoint(x: ox + 25 * scale, y: oy - 25 * scale))
        path.addLine(to: CGPoint(x: ox + 54 * scale, y: oy))
        path.closeSubpath()

        // Pillars
        path.move(to: CGPoint(x: ox + 4 * scale, y: oy))
        path.addLine(to: CGPoint(x: ox + 4 * scale, y: oy + 45 * scale))
        path.move(to: CGPoint(x: ox + 18 * scale, y: oy))
        path.addLine(to: CGPoint(x: ox + 18 * scale, y: oy + 45 * scale))
        path.move(to: CGPoint(x: ox + 32 * scale, y: oy))
        path.addLine(to: CGPoint(x: ox + 32 * scale, y: oy + 45 * scale))
        path.move(to: CGPoint(x: ox + 46 * scale, y: oy))
        path.addLine(to: CGPoint(x: ox + 46 * scale, y: oy + 45 * scale))

        // Balinese ornament / Penjor curl on right
        path.move(to: CGPoint(x: ox + 62 * scale, y: oy + 45 * scale))
        path.addQuadCurve(to: CGPoint(x: ox + 72 * scale, y: oy - 15 * scale), control: CGPoint(x: ox + 60 * scale, y: oy + 10 * scale))
        path.addQuadCurve(to: CGPoint(x: ox + 65 * scale, y: oy - 25 * scale), control: CGPoint(x: ox + 78 * scale, y: oy - 22 * scale))
        path.move(to: CGPoint(x: ox + 68 * scale, y: oy + 35 * scale))
        path.addQuadCurve(to: CGPoint(x: ox + 82 * scale, y: oy + 10 * scale), control: CGPoint(x: ox + 72 * scale, y: oy + 25 * scale))
        path.move(to: CGPoint(x: ox + 70 * scale, y: oy + 20 * scale))
        path.addQuadCurve(to: CGPoint(x: ox + 86 * scale, y: oy - 2 * scale), control: CGPoint(x: ox + 76 * scale, y: oy + 10 * scale))
        return path
    }

    private func drawTraveler(scale: CGFloat, origin: CGPoint) -> Path {
        var path = Path()
        let ox = origin.x
        let oy = origin.y
        // Head
        path.addEllipse(in: CGRect(x: ox - 6 * scale, y: oy - 55 * scale, width: 14 * scale, height: 16 * scale))
        // Torso
        path.move(to: CGPoint(x: ox + 1 * scale, y: oy - 39 * scale))
        path.addLine(to: CGPoint(x: ox + 6 * scale, y: oy - 12 * scale))
        // Legs
        path.move(to: CGPoint(x: ox + 6 * scale, y: oy - 12 * scale))
        path.addLine(to: CGPoint(x: ox + 9 * scale, y: oy + 20 * scale))
        path.addLine(to: CGPoint(x: ox + 18 * scale, y: oy + 18 * scale))

        path.move(to: CGPoint(x: ox + 6 * scale, y: oy - 12 * scale))
        path.addLine(to: CGPoint(x: ox + 20 * scale, y: oy + 12 * scale))
        path.addLine(to: CGPoint(x: ox + 28 * scale, y: oy + 10 * scale))

        // Arms
        path.move(to: CGPoint(x: ox + 2 * scale, y: oy - 32 * scale))
        path.addLine(to: CGPoint(x: ox + 18 * scale, y: oy - 18 * scale))
        path.addLine(to: CGPoint(x: ox + 26 * scale, y: oy - 30 * scale))

        // Backpack
        path.move(to: CGPoint(x: ox - 4 * scale, y: oy - 34 * scale))
        path.addQuadCurve(to: CGPoint(x: ox - 2 * scale, y: oy - 14 * scale), control: CGPoint(x: ox - 18 * scale, y: oy - 24 * scale))
        path.addLine(to: CGPoint(x: ox + 5 * scale, y: oy - 14 * scale))
        path.addLine(to: CGPoint(x: ox + 2 * scale, y: oy - 34 * scale))
        path.closeSubpath()
        return path
    }

    private func drawDiamond(into path: inout Path, center: CGPoint, radius: CGFloat) {
        path.move(to: CGPoint(x: center.x, y: center.y - radius))
        path.addLine(to: CGPoint(x: center.x + radius, y: center.y))
        path.addLine(to: CGPoint(x: center.x, y: center.y + radius))
        path.addLine(to: CGPoint(x: center.x - radius, y: center.y))
        path.closeSubpath()
    }
}

#Preview {
    NowHeroIllustrationView()
        .frame(height: 300)
        .padding()
        .background(Color(red: 248/255, green: 247/255, blue: 244/255))
}
