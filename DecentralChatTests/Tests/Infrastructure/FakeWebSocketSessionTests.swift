import DecentralChatCore
import Foundation
import XCTest
@testable import DecentralChat

final class FakeWebSocketSessionTests: XCTestCase {
    func testConnectSuccessPath() async throws {
        let session = FakeWebSocketSession()

        try await session.connect()

        XCTAssertTrue(session.isConnected)
    }

    func testConnectFailurePath() async {
        let session = FakeWebSocketSession()
        session.shouldFailConnect = true

        do {
            try await session.connect()
            XCTFail("Expected FakeWebSocketSessionError.connectFailed")
        } catch let error as FakeWebSocketSessionError {
            XCTAssertEqual(error, .connectFailed)
        } catch {
            XCTFail("Expected FakeWebSocketSessionError.connectFailed, got \(error)")
        }
    }

    func testSendStringRecordsOutgoingString() async throws {
        let session = FakeWebSocketSession()

        try await session.sendString("message-json")

        XCTAssertEqual(session.sentStrings, ["message-json"])
    }

    func testSendStringFailureThrows() async {
        let session = FakeWebSocketSession()
        session.shouldFailSend = true

        do {
            try await session.sendString("message-json")
            XCTFail("Expected FakeWebSocketSessionError.sendFailed")
        } catch let error as FakeWebSocketSessionError {
            XCTAssertEqual(error, .sendFailed)
        } catch {
            XCTFail("Expected FakeWebSocketSessionError.sendFailed, got \(error)")
        }
    }

    func testReceiveStringReturnsQueuedIncomingString() async throws {
        let session = FakeWebSocketSession(incomingStrings: ["incoming-json"])

        let receivedString = try await session.receiveString()

        XCTAssertEqual(receivedString, "incoming-json")
    }

    func testReceiveStringFailureThrows() async {
        let session = FakeWebSocketSession()
        session.shouldFailReceive = true

        do {
            _ = try await session.receiveString()
            XCTFail("Expected FakeWebSocketSessionError.receiveFailed")
        } catch let error as FakeWebSocketSessionError {
            XCTAssertEqual(error, .receiveFailed)
        } catch {
            XCTFail("Expected FakeWebSocketSessionError.receiveFailed, got \(error)")
        }
    }

    func testDisconnectCompletesSafelyAndClearsConnectedState() async throws {
        let session = FakeWebSocketSession()
        try await session.connect()

        await session.disconnect()

        XCTAssertFalse(session.isConnected)
    }

    func testObserveStateCanEmitAndReceiveStateEvents() async {
        let session = FakeWebSocketSession()
        let stream = await session.observeState()
        var iterator = stream.makeAsyncIterator()

        session.emitState(.connecting)
        let state = await iterator.next()

        XCTAssertEqual(state, .connecting)
    }
}

private final class FakeWebSocketSession: WebSocketSessionProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var incomingStrings: [String]
    private var stateContinuations: [UUID: AsyncStream<TransportState>.Continuation] = [:]
    private var _sentStrings: [String] = []
    private var _isConnected = false
    private var _shouldFailConnect = false
    private var _shouldFailSend = false
    private var _shouldFailReceive = false

    var sentStrings: [String] {
        lock.withLock {
            _sentStrings
        }
    }

    var isConnected: Bool {
        lock.withLock {
            _isConnected
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
            throw FakeWebSocketSessionError.connectFailed
        }

        lock.withLock {
            _isConnected = true
        }
        emitState(.connected)
    }

    func disconnect() async {
        lock.withLock {
            _isConnected = false
        }
        emitState(.disconnected)
    }

    func sendString(_ text: String) async throws {
        let shouldFailSend = lock.withLock {
            _shouldFailSend
        }

        if shouldFailSend {
            throw FakeWebSocketSessionError.sendFailed
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
            throw FakeWebSocketSessionError.receiveFailed
        }

        return try lock.withLock {
            guard !incomingStrings.isEmpty else {
                throw FakeWebSocketSessionError.noIncomingString
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

private enum FakeWebSocketSessionError: Error, Equatable {
    case connectFailed
    case sendFailed
    case receiveFailed
    case noIncomingString
}
