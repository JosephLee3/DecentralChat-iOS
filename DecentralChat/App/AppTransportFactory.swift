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

    static func makeTransport(
        configuration: TransportConfiguration = .mock,
        relayTaskFactory: WebSocketTaskFactoryProtocol? = nil
    ) throws -> Result {
        switch configuration.mode {
        case .mock:
            return makeMockTransport()
        case .relayWebSocket:
            guard configuration.isValid else {
                throw FactoryError.invalidRelayConfiguration
            }

            guard let relayURL = configuration.relayURL, let relayTaskFactory else {
                throw FactoryError.relayWebSocketNotImplemented
            }

            let task = relayTaskFactory.makeTask(url: relayURL)
            let session = URLSessionWebSocketSession(task: task)
            let transport = RelayWebSocketTransport(session: session)

#if DEBUG
            return Result(transport: transport, debugMockTransport: nil)
#else
            return Result(transport: transport)
#endif
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
