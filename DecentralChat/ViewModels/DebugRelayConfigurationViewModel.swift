#if DEBUG
import Combine
import Foundation

@MainActor
final class DebugRelayConfigurationViewModel: ObservableObject {
    @Published var relayURLText: String {
        didSet {
            validateRelayURL()
        }
    }

    @Published private(set) var validationMessage: String?
    @Published private(set) var isValid: Bool

    init(relayURLText: String = "") {
        self.relayURLText = relayURLText
        self.validationMessage = nil
        self.isValid = false
        validateRelayURL()
    }

    var transportConfiguration: TransportConfiguration? {
        guard let relayURL = validRelayURL else {
            return nil
        }

        return TransportConfiguration(
            mode: .relayWebSocket,
            relayURL: relayURL,
            connectionTimeoutSeconds: TransportConfiguration.mock.connectionTimeoutSeconds
        )
    }

    func validateRelayURL() {
        let trimmedRelayURLText = relayURLText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedRelayURLText.isEmpty else {
            setInvalid("Relay URL is required.")
            return
        }

        guard let relayURL = URL(string: trimmedRelayURLText) else {
            setInvalid("Relay URL is invalid.")
            return
        }

        guard relayURL.scheme?.lowercased() == "wss" else {
            setInvalid("Relay URL must start with wss://.")
            return
        }

        guard relayURL.host?.isEmpty == false else {
            setInvalid("Relay URL must include a host.")
            return
        }

        validationMessage = "Relay URL is valid."
        isValid = true
    }

    private var validRelayURL: URL? {
        guard isValid else {
            return nil
        }

        return URL(string: relayURLText.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func setInvalid(_ message: String) {
        validationMessage = message
        isValid = false
    }
}
#endif
