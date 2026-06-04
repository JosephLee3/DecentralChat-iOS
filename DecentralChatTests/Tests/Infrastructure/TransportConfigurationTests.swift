import XCTest
@testable import DecentralChat

final class TransportConfigurationTests: XCTestCase {
    func testDefaultMockConfigIsValid() {
        XCTAssertTrue(TransportConfiguration.mock.isValid)
        XCTAssertEqual(TransportConfiguration.mock.mode, .mock)
    }

    func testMockConfigDoesNotRequireRelayURL() {
        let configuration = TransportConfiguration(
            mode: .mock,
            relayURL: nil,
            connectionTimeoutSeconds: 30
        )

        XCTAssertTrue(configuration.isValid)
    }

    func testRelayConfigWithWSSURLIsValid() {
        let configuration = TransportConfiguration(
            mode: .relayWebSocket,
            relayURL: URL(string: "wss://relay.example.com/chat"),
            connectionTimeoutSeconds: 30
        )

        XCTAssertTrue(configuration.isValid)
    }

    func testRelayConfigWithoutURLIsInvalid() {
        let configuration = TransportConfiguration(
            mode: .relayWebSocket,
            relayURL: nil,
            connectionTimeoutSeconds: 30
        )

        XCTAssertFalse(configuration.isValid)
    }

    func testRelayConfigWithHTTPURLIsInvalid() {
        let configuration = TransportConfiguration(
            mode: .relayWebSocket,
            relayURL: URL(string: "http://relay.example.com/chat"),
            connectionTimeoutSeconds: 30
        )

        XCTAssertFalse(configuration.isValid)
    }

    func testRelayConfigWithHTTPSURLIsInvalid() {
        let configuration = TransportConfiguration(
            mode: .relayWebSocket,
            relayURL: URL(string: "https://relay.example.com/chat"),
            connectionTimeoutSeconds: 30
        )

        XCTAssertFalse(configuration.isValid)
    }

    func testRelayConfigWithWSURLIsInvalid() {
        let configuration = TransportConfiguration(
            mode: .relayWebSocket,
            relayURL: URL(string: "ws://relay.example.com/chat"),
            connectionTimeoutSeconds: 30
        )

        XCTAssertFalse(configuration.isValid)
    }

    func testCodableRoundTripPreservesValues() throws {
        let configuration = TransportConfiguration(
            mode: .relayWebSocket,
            relayURL: URL(string: "wss://relay.example.com/chat"),
            connectionTimeoutSeconds: 15
        )

        let data = try JSONEncoder().encode(configuration)
        let decoded = try JSONDecoder().decode(TransportConfiguration.self, from: data)

        XCTAssertEqual(decoded, configuration)
        XCTAssertEqual(decoded.mode, .relayWebSocket)
        XCTAssertEqual(decoded.relayURL, URL(string: "wss://relay.example.com/chat"))
        XCTAssertEqual(decoded.connectionTimeoutSeconds, 15)
    }
}
