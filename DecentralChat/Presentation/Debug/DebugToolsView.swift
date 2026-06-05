#if DEBUG
import SwiftUI

struct DebugToolsView: View {
    @StateObject private var relayConfigurationViewModel = DebugRelayConfigurationViewModel()
    @State private var isShowingResetConfirmation = false
    @State private var isShowingResetResult = false
    @State private var resetResultTitle = ""
    @State private var resetResultMessage = ""

    var body: some View {
        Form {
            Section("Relay") {
                TextField(
                    "wss://relay.example.com",
                    text: $relayConfigurationViewModel.relayURLText
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)

                Button("Validate Relay URL") {
                    relayConfigurationViewModel.validateRelayURL()
                }

                if let validationMessage = relayConfigurationViewModel.validationMessage {
                    Text(validationMessage)
                }

                if relayConfigurationViewModel.isValid {
                    Text("Relay URL is valid. Runtime relay is not enabled yet.")
                }
            }

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
