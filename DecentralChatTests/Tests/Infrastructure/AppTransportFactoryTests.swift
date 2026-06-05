import DecentralChatCore
import XCTest
@testable import DecentralChat

final class AppTransportFactoryTests: XCTestCase {
    func testMockConfigurationReturnsUsableMockTransport() throws {
        let result = try AppTransportFactory.makeTransport(configuration: .mock)

        XCTAssertTrue(result.transport is MockTransport)

#if DEBUG
        let mockTransport = try XCTUnwrap(result.transport as? MockTransport)
        let debugMockTransport = try XCTUnwrap(result.debugMockTransport)

        XCTAssertTrue(mockTransport === debugMockTransport)
#endif
    }

    func testRelayConfigurationWithoutURLThrowsInvalidConfiguration() {
        let configuration = TransportConfiguration(
            mode: .relayWebSocket,
            relayURL: nil,
            connectionTimeoutSeconds: 30
        )

        assertFactoryThrowsInvalidRelayConfiguration(configuration)
    }

    func testRelayConfigurationWithHTTPURLThrowsInvalidConfiguration() {
        let configuration = TransportConfiguration(
            mode: .relayWebSocket,
            relayURL: URL(string: "http://relay.example.com/chat"),
            connectionTimeoutSeconds: 30
        )

        assertFactoryThrowsInvalidRelayConfiguration(configuration)
    }

    func testRelayConfigurationWithHTTPSURLThrowsInvalidConfiguration() {
        let configuration = TransportConfiguration(
            mode: .relayWebSocket,
            relayURL: URL(string: "https://relay.example.com/chat"),
            connectionTimeoutSeconds: 30
        )

        assertFactoryThrowsInvalidRelayConfiguration(configuration)
    }

    func testRelayConfigurationWithWSURLThrowsInvalidConfiguration() {
        let configuration = TransportConfiguration(
            mode: .relayWebSocket,
            relayURL: URL(string: "ws://relay.example.com/chat"),
            connectionTimeoutSeconds: 30
        )

        assertFactoryThrowsInvalidRelayConfiguration(configuration)
    }

    func testRelayConfigurationWithWSSURLThrowsUnsupportedRelayRuntime() {
        let configuration = TransportConfiguration(
            mode: .relayWebSocket,
            relayURL: URL(string: "wss://relay.example.com/chat"),
            connectionTimeoutSeconds: 30
        )

        XCTAssertThrowsError(try AppTransportFactory.makeTransport(configuration: configuration)) { error in
            XCTAssertEqual(error as? AppTransportFactory.FactoryError, .relayWebSocketNotImplemented)
        }
    }

    func testRelayConfigurationWithWSSURLAndFakeTaskFactoryBuildsRelayTransport() throws {
        let relayURL = try XCTUnwrap(URL(string: "wss://relay.example.com/chat"))
        let configuration = TransportConfiguration(
            mode: .relayWebSocket,
            relayURL: relayURL,
            connectionTimeoutSeconds: 30
        )
        let task = FakeAppTransportFactoryWebSocketTask()
        let factory = FakeAppTransportFactoryWebSocketTaskFactory(task: task)

        let result = try AppTransportFactory.makeTransport(
            configuration: configuration,
            relayTaskFactory: factory
        )

        XCTAssertTrue(result.transport is RelayWebSocketTransport)
        XCTAssertFalse(result.transport is MockTransport)
        XCTAssertEqual(factory.requestedURLs, [relayURL])

#if DEBUG
        XCTAssertNil(result.debugMockTransport)
#endif
    }

    func testAppContainerDefaultBehaviorUsesMockTransport() {
        let container = try! AppContainer()

        XCTAssertTrue(container.transport is MockTransport)

#if DEBUG
        let mockTransport = container.transport as? MockTransport

        XCTAssertNotNil(mockTransport)
        XCTAssertTrue(mockTransport === container.debugMockTransport)
#endif
    }

    private func assertFactoryThrowsInvalidRelayConfiguration(
        _ configuration: TransportConfiguration,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertThrowsError(
            try AppTransportFactory.makeTransport(configuration: configuration),
            file: file,
            line: line
        ) { error in
            XCTAssertEqual(
                error as? AppTransportFactory.FactoryError,
                .invalidRelayConfiguration,
                file: file,
                line: line
            )
        }
    }
}

private final class FakeAppTransportFactoryWebSocketTaskFactory: WebSocketTaskFactoryProtocol, @unchecked Sendable {
    private let task: WebSocketTaskProtocol
    private(set) var requestedURLs: [URL] = []

    init(task: WebSocketTaskProtocol) {
        self.task = task
    }

    func makeTask(url: URL) -> WebSocketTaskProtocol {
        requestedURLs.append(url)
        return task
    }
}

private final class FakeAppTransportFactoryWebSocketTask: WebSocketTaskProtocol, @unchecked Sendable {
    func resume() {}

    func cancel() {}

    func sendString(_ text: String) async throws {}

    func receiveString() async throws -> String {
        throw FakeAppTransportFactoryWebSocketTaskError.noIncomingString
    }
}

private enum FakeAppTransportFactoryWebSocketTaskError: Error {
    case noIncomingString
}
