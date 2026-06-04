import DecentralChatCore
import XCTest
@testable import DecentralChat

final class AppContainerTransportConfigurationTests: XCTestCase {
    func testDefaultAppContainerSucceedsAndUsesMockTransport() throws {
        let container = try AppContainer()

        XCTAssertTrue(container.transport is MockTransport)
    }

    func testMockTransportConfigurationSucceeds() throws {
        let container = try AppContainer(
            messageStore: InMemoryMessageStore(),
            identityStore: InMemoryIdentityStore(),
            contactStore: InMemoryContactStore(),
            transportConfiguration: .mock
        )

        XCTAssertTrue(container.transport is MockTransport)
    }

    func testInjectedMockTransportIsUsed() throws {
        let injectedTransport = MockTransport()
        let container = try AppContainer(
            messageStore: InMemoryMessageStore(),
            identityStore: InMemoryIdentityStore(),
            contactStore: InMemoryContactStore(),
            transport: injectedTransport,
            transportConfiguration: relayConfiguration(urlString: "wss://relay.example.com/chat")
        )

        let mockTransport = try XCTUnwrap(container.transport as? MockTransport)
        XCTAssertTrue(mockTransport === injectedTransport)
    }

#if DEBUG
    func testDefaultAppContainerExposesDebugMockTransport() throws {
        let container = try AppContainer()
        let mockTransport = try XCTUnwrap(container.transport as? MockTransport)

        XCTAssertTrue(mockTransport === container.debugMockTransport)
    }

    func testMockTransportConfigurationExposesDebugMockTransport() throws {
        let container = try AppContainer(
            messageStore: InMemoryMessageStore(),
            identityStore: InMemoryIdentityStore(),
            contactStore: InMemoryContactStore(),
            transportConfiguration: .mock
        )
        let mockTransport = try XCTUnwrap(container.transport as? MockTransport)

        XCTAssertTrue(mockTransport === container.debugMockTransport)
    }

    func testInjectedMockTransportIsUsedAsDebugMockTransport() throws {
        let injectedTransport = MockTransport()
        let container = try AppContainer(
            messageStore: InMemoryMessageStore(),
            identityStore: InMemoryIdentityStore(),
            contactStore: InMemoryContactStore(),
            transport: injectedTransport
        )

        XCTAssertTrue(injectedTransport === container.debugMockTransport)
    }
#endif

    func testInvalidRelayConfigurationThrowsExplicitError() {
        let configuration = relayConfiguration(urlString: "https://relay.example.com/chat")

        XCTAssertThrowsError(
            try AppContainer(
                messageStore: InMemoryMessageStore(),
                identityStore: InMemoryIdentityStore(),
                contactStore: InMemoryContactStore(),
                transportConfiguration: configuration
            )
        ) { error in
            XCTAssertEqual(error as? AppTransportFactory.FactoryError, .invalidRelayConfiguration)
        }
    }

    func testValidRelayConfigurationThrowsUnsupportedRelayRuntime() {
        let configuration = relayConfiguration(urlString: "wss://relay.example.com/chat")

        XCTAssertThrowsError(
            try AppContainer(
                messageStore: InMemoryMessageStore(),
                identityStore: InMemoryIdentityStore(),
                contactStore: InMemoryContactStore(),
                transportConfiguration: configuration
            )
        ) { error in
            XCTAssertEqual(error as? AppTransportFactory.FactoryError, .relayWebSocketNotImplemented)
        }
    }

    private func relayConfiguration(urlString: String) -> TransportConfiguration {
        TransportConfiguration(
            mode: .relayWebSocket,
            relayURL: URL(string: urlString),
            connectionTimeoutSeconds: 30
        )
    }
}
