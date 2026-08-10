import SwiftUI

struct MapView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView("Map", systemImage: "map", description: Text("Sites appear here in slice 6."))
                .navigationTitle("Map")
        }
    }
}

#Preview {
    MapView()
}
