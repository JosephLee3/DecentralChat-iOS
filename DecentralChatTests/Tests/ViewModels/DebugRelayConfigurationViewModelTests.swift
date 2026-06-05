#if DEBUG
import XCTest
@testable import DecentralChat

@MainActor
final class DebugRelayConfigurationViewModelTests: XCTestCase {
    func testEmptyStringIsInvalid() {
        let viewModel = DebugRelayConfigurationViewModel(relayURLText: "")

        XCTAssertFalse(viewModel.isValid)
        XCTAssertNotNil(viewModel.validationMessage)
        XCTAssertNil(viewModel.transportConfiguration)
    }

    func testMalformedURLIsInvalid() {
        let viewModel = DebugRelayConfigurationViewModel(relayURLText: "not a url")

        XCTAssertFalse(viewModel.isValid)
        XCTAssertNotNil(viewModel.validationMessage)
        XCTAssertNil(viewModel.transportConfiguration)
    }

    func testHTTPURLIsInvalid() {
        let viewModel = DebugRelayConfigurationViewModel(relayURLText: "http://relay.example.com/chat")

        XCTAssertFalse(viewModel.isValid)
        XCTAssertNotNil(viewModel.validationMessage)
        XCTAssertNil(viewModel.transportConfiguration)
    }

    func testHTTPSURLIsInvalid() {
        let viewModel = DebugRelayConfigurationViewModel(relayURLText: "https://relay.example.com/chat")

        XCTAssertFalse(viewModel.isValid)
        XCTAssertNotNil(viewModel.validationMessage)
        XCTAssertNil(viewModel.transportConfiguration)
    }

    func testWSURLIsInvalid() {
        let viewModel = DebugRelayConfigurationViewModel(relayURLText: "ws://relay.example.com/chat")

        XCTAssertFalse(viewModel.isValid)
        XCTAssertNotNil(viewModel.validationMessage)
        XCTAssertNil(viewModel.transportConfiguration)
    }

    func testWSSURLWithValidHostIsValid() {
        let viewModel = DebugRelayConfigurationViewModel(relayURLText: "wss://relay.example.com/chat")

        XCTAssertTrue(viewModel.isValid)
        XCTAssertNotNil(viewModel.validationMessage)
    }

    func testValidConfigurationOutputUsesRelayWebSocketModeAndRelayURL() throws {
        let relayURL = try XCTUnwrap(URL(string: "wss://relay.example.com/chat"))
        let viewModel = DebugRelayConfigurationViewModel(relayURLText: "  \(relayURL.absoluteString)  ")

        let configuration = try XCTUnwrap(viewModel.transportConfiguration)

        XCTAssertEqual(configuration.mode, .relayWebSocket)
        XCTAssertEqual(configuration.relayURL, relayURL)
        XCTAssertEqual(
            configuration.connectionTimeoutSeconds,
            TransportConfiguration.mock.connectionTimeoutSeconds
        )
        XCTAssertTrue(configuration.isValid)
    }
}
#endif
