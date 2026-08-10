import SwiftUI

struct HistoryView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView("History", systemImage: "clock", description: Text("Past walks appear here in slice 8."))
                .navigationTitle("History")
        }
    }
}

#Preview {
    HistoryView()
}
