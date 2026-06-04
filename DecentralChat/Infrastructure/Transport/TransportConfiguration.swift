import Foundation

struct TransportConfiguration: Codable, Equatable {
    enum Mode: String, Codable {
        case mock
        case relayWebSocket
    }

    let mode: Mode
    let relayURL: URL?
    let connectionTimeoutSeconds: TimeInterval

    static let mock = TransportConfiguration(
        mode: .mock,
        relayURL: nil,
        connectionTimeoutSeconds: 30
    )

    var isValid: Bool {
        switch mode {
        case .mock:
            return true
        case .relayWebSocket:
            return relayURL?.scheme?.lowercased() == "wss"
        }
    }
}
