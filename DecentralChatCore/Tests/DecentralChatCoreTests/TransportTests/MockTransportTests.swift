import DecentralChatCore
import Foundation
import XCTest

final class MockTransportTests: XCTestCase {
    func testConnectEmitsConnectedState() async throws {
        let transport = MockTransport()
        let stream = transport.observeState()
        var iterator = stream.makeAsyncIterator()

        let initialState = await iterator.next()
        try await transport.connect()
        let connectedState = await iterator.next()

        XCTAssertEqual(initialState, .idle)
        XCTAssertEqual(connectedState, .connected)
    }

    func testDisconnectEmitsDisconnectedState() async throws {
        let transport = MockTransport()
        let stream = transport.observeState()
        var iterator = stream.makeAsyncIterator()

        _ = await iterator.next()
        await transport.disconnect()
        let disconnectedState = await iterator.next()

        XCTAssertEqual(disconnectedState, .disconnected)
    }

    func testSendRecordsEnvelope() async throws {
        let transport = MockTransport()
        let envelope = makeEnvelope(id: "envelope-1")

        try await transport.send(envelope)

        XCTAssertEqual(transport.sentEnvelopes, [envelope])
    }

    func testSendThrowsSendFailedWhenShouldFailSendIsTrue() async {
        let transport = MockTransport()
        transport.shouldFailSend = true

        do {
            try await transport.send(makeEnvelope(id: "envelope-1"))
            XCTFail("Expected TransportError.sendFailed")
        } catch let error as TransportError {
            XCTAssertEqual(error, .sendFailed)
        } catch {
            XCTFail("Expected TransportError.sendFailed, got \(error)")
        }
    }

    func testSimulateIncomingEmitsEnvelopeThroughAsyncStream() async {
        let transport = MockTransport()
        let envelope = makeEnvelope(id: "envelope-1")
        let stream = transport.observeIncomingMessages()
        var iterator = stream.makeAsyncIterator()

        transport.simulateIncoming(envelope)
        let receivedEnvelope = await iterator.next()

        XCTAssertEqual(receivedEnvelope, envelope)
    }

    func testObserveStateInitiallyEmitsIdle() async {
        let transport = MockTransport()
        let stream = transport.observeState()
        var iterator = stream.makeAsyncIterator()

        let initialState = await iterator.next()

        XCTAssertEqual(initialState, .idle)
    }

    private func makeEnvelope(id: String) -> MessageEnvelope {
        MessageEnvelope(
            id: id,
            version: 1,
            type: .chatMessage,
            senderPublicKey: "sender-public-key",
            receiverPublicKey: "receiver-public-key",
            conversationID: "conversation-1",
            ciphertext: "mock-ciphertext",
            createdAt: Date(timeIntervalSince1970: 100),
            expiresAt: nil,
            nonce: "mock-nonce",
            signature: "mock-signature"
        )
    }
}
