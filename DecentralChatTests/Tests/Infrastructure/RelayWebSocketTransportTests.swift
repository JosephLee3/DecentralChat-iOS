import DecentralChatCore
import Foundation
import XCTest
@testable import DecentralChat

final class RelayWebSocketTransportTests: XCTestCase {
    func testConnectDelegatesToSession() async throws {
        let session = RelayTestWebSocketSession()
        let transport = RelayWebSocketTransport(session: session)

        try await transport.connect()

        XCTAssertTrue(session.didConnect)
    }

    func testDisconnectDelegatesToSession() async {
        let session = RelayTestWebSocketSession()
        let transport = RelayWebSocketTransport(session: session)

        await transport.disconnect()

        XCTAssertTrue(session.didDisconnect)
    }

    func testSendEncodesEnvelopeAndRecordsOutgoingJSONString() async throws {
        let session = RelayTestWebSocketSession()
        let codec = MessageEnvelopeWireCodec()
        let transport = RelayWebSocketTransport(session: session, codec: codec)
        let envelope = makeEnvelope(id: "outgoing")

        try await transport.send(envelope)

        let sentString = try XCTUnwrap(session.sentStrings.first)
        let sentData = try XCTUnwrap(sentString.data(using: .utf8))
        XCTAssertEqual(try codec.decode(sentData), envelope)
    }

    func testSendFailureThrows() async {
        let session = RelayTestWebSocketSession()
        session.shouldFailSend = true
        let transport = RelayWebSocketTransport(session: session)

        do {
            try await transport.send(makeEnvelope())
            XCTFail("Expected RelayTestWebSocketSessionError.sendFailed")
        } catch let error as RelayTestWebSocketSessionError {
            XCTAssertEqual(error, .sendFailed)
        } catch {
            XCTFail("Expected RelayTestWebSocketSessionError.sendFailed, got \(error)")
        }
    }

    func testObserveIncomingMessagesYieldsDecodedEnvelopeFromQueuedJSONString() async throws {
        let codec = MessageEnvelopeWireCodec()
        let envelope = makeEnvelope(id: "incoming")
        let data = try codec.encode(envelope)
        let jsonString = try XCTUnwrap(String(data: data, encoding: .utf8))
        let session = RelayTestWebSocketSession(incomingStrings: [jsonString])
        let transport = RelayWebSocketTransport(session: session, codec: codec)
        let stream = transport.observeIncomingMessages()
        var iterator = stream.makeAsyncIterator()

        let receivedEnvelope = await iterator.next()

        XCTAssertEqual(receivedEnvelope, envelope)
    }

    func testMalformedIncomingJSONDoesNotCrashAndContinuesToNextFrame() async throws {
        let codec = MessageEnvelopeWireCodec()
        let envelope = makeEnvelope(id: "valid-after-malformed")
        let data = try codec.encode(envelope)
        let jsonString = try XCTUnwrap(String(data: data, encoding: .utf8))
        let session = RelayTestWebSocketSession(incomingStrings: ["not-json", jsonString])
        let transport = RelayWebSocketTransport(session: session, codec: codec)
        let stream = transport.observeIncomingMessages()
        var iterator = stream.makeAsyncIterator()

        let receivedEnvelope = await iterator.next()

        XCTAssertEqual(receivedEnvelope, envelope)
    }

    func testObserveStateForwardsSessionStateEvents() async {
        let session = RelayTestWebSocketSession()
        let transport = RelayWebSocketTransport(session: session)
        let stream = await transport.observeState()
        var iterator = stream.makeAsyncIterator()

        session.emitState(.connecting)
        let state = await iterator.next()

        XCTAssertEqual(state, .connecting)
    }
}

private final class RelayTestWebSocketSession: WebSocketSessionProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var incomingStrings: [String]
    private var stateContinuations: [UUID: AsyncStream<TransportState>.Continuation] = [:]
    private var _didConnect = false
    private var _didDisconnect = false
    private var _sentStrings: [String] = []
    private var _shouldFailConnect = false
    private var _shouldFailSend = false
    private var _shouldFailReceive = false

    var didConnect: Bool {
        lock.withLock {
            _didConnect
        }
    }

    var didDisconnect: Bool {
        lock.withLock {
            _didDisconnect
        }
    }

    var sentStrings: [String] {
        lock.withLock {
            _sentStrings
        }
    }

    var shouldFailConnect: Bool {
        get {
            lock.withLock {
                _shouldFailConnect
            }
        }
        set {
            lock.withLock {
                _shouldFailConnect = newValue
            }
        }
    }

    var shouldFailSend: Bool {
        get {
            lock.withLock {
                _shouldFailSend
            }
        }
        set {
            lock.withLock {
                _shouldFailSend = newValue
            }
        }
    }

    var shouldFailReceive: Bool {
        get {
            lock.withLock {
                _shouldFailReceive
            }
        }
        set {
            lock.withLock {
                _shouldFailReceive = newValue
            }
        }
    }

    init(incomingStrings: [String] = []) {
        self.incomingStrings = incomingStrings
    }

    func connect() async throws {
        let shouldFailConnect = lock.withLock {
            _shouldFailConnect
        }

        if shouldFailConnect {
            throw RelayTestWebSocketSessionError.connectFailed
        }

        lock.withLock {
            _didConnect = true
        }
    }

    func disconnect() async {
        lock.withLock {
            _didDisconnect = true
        }
    }

    func sendString(_ text: String) async throws {
        let shouldFailSend = lock.withLock {
            _shouldFailSend
        }

        if shouldFailSend {
            throw RelayTestWebSocketSessionError.sendFailed
        }

        lock.withLock {
            _sentStrings.append(text)
        }
    }

    func receiveString() async throws -> String {
        let shouldFailReceive = lock.withLock {
            _shouldFailReceive
        }

        if shouldFailReceive {
            throw RelayTestWebSocketSessionError.receiveFailed
        }

        return try lock.withLock {
            guard !incomingStrings.isEmpty else {
                throw RelayTestWebSocketSessionError.noIncomingString
            }

            return incomingStrings.removeFirst()
        }
    }

    func observeState() -> AsyncStream<TransportState> {
        AsyncStream { continuation in
            let id = UUID()

            lock.withLock {
                stateContinuations[id] = continuation
            }

            continuation.onTermination = { [weak self] _ in
                self?.lock.withLock {
                    self?.stateContinuations[id] = nil
                }
            }
        }
    }

    func emitState(_ state: TransportState) {
        let continuations = lock.withLock {
            Array(stateContinuations.values)
        }

        continuations.forEach { continuation in
            continuation.yield(state)
        }
    }
}

private enum RelayTestWebSocketSessionError: Error, Equatable {
    case connectFailed
    case sendFailed
    case receiveFailed
    case noIncomingString
}

private func makeEnvelope(id: String = "envelope") -> MessageEnvelope {
    MessageEnvelope(
        id: id,
        version: 1,
        type: .chatMessage,
        senderPublicKey: "sender-public-key",
        receiverPublicKey: "receiver-public-key",
        conversationID: "conversation-id",
        ciphertext: "ciphertext",
        createdAt: Date(timeIntervalSince1970: 1_234),
        expiresAt: nil,
        nonce: "nonce",
        signature: "signature"
    )
}
