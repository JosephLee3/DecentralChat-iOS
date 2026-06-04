#if DEBUG
import SwiftUI

struct DebugToolsView: View {
    @State private var isShowingResetConfirmation = false
    @State private var isShowingResetResult = false
    @State private var resetResultTitle = ""
    @State private var resetResultMessage = ""

    var body: some View {
        Form {
            Section {
                Button("Reset Data", role: .destructive) {
                    isShowingResetConfirmation = true
                }
            }
        }
        .navigationTitle("Debug Tools")
        .alert("Reset Local Data?", isPresented: $isShowingResetConfirmation) {
            Button("Cancel", role: .cancel) {}

            Button("Reset", role: .destructive) {
                resetLocalMockData()
            }
        } message: {
            Text("This deletes local mock contacts, messages, and identity JSON files. Restart the app after reset.")
        }
        .alert(resetResultTitle, isPresented: $isShowingResetResult) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(resetResultMessage)
        }
    }

    private func resetLocalMockData() {
        do {
            try AppContainer.shared.resetLocalMockData()
            resetResultTitle = "Reset Complete"
            resetResultMessage = "Reset complete. Restart the app."
        } catch {
            resetResultTitle = "Reset Failed"
            resetResultMessage = error.localizedDescription
        }

        isShowingResetResult = true
    }
}

#Preview {
    NavigationStack {
        DebugToolsView()
    }
}
#endif
