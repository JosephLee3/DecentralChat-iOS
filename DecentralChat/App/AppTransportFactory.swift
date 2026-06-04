import DecentralChatCore
import Foundation

enum AppTransportFactory {
    struct Result {
        let transport: ChatTransport
#if DEBUG
        let debugMockTransport: MockTransport?
#endif
    }

    enum FactoryError: Error {
        case invalidRelayConfiguration
        case relayWebSocketNotImplemented
    }

    static func makeTransport(configuration: TransportConfiguration = .mock) throws -> Result {
        switch configuration.mode {
        case .mock:
            return makeMockTransport()
        case .relayWebSocket:
            guard configuration.isValid else {
                throw FactoryError.invalidRelayConfiguration
            }

            // TODO: Build RelayWebSocketTransport with URLSessionWebSocketSession
            // and URLSessionWebSocketTaskAdapter once runtime relay mode is enabled.
            throw FactoryError.relayWebSocketNotImplemented
        }
    }

    static func makeMockTransport() -> Result {
        let transport = MockTransport()

#if DEBUG
        return Result(transport: transport, debugMockTransport: transport)
#else
        return Result(transport: transport)
#endif
    }
}
