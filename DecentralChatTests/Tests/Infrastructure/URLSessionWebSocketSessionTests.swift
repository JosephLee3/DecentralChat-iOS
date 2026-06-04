import DecentralChatCore
import Foundation
import XCTest
@testable import DecentralChat

final class URLSessionWebSocketSessionTests: XCTestCase {
    func testConnectResumesTaskAndEmitsConnectingThenConnected() async throws {
        let task = SessionTestWebSocketTask()
        let session = URLSessionWebSocketSession(task: task)
        let stream = await session.observeState()
        var iterator = stream.makeAsyncIterator()

        try await session.connect()

        let connecting = await iterator.next()
        let connected = await iterator.next()
        XCTAssertTrue(task.didResume)
        XCTAssertEqual(connecting, .connecting)
        XCTAssertEqual(connected, .connected)
    }

    func testDisconnectCancelsTaskAndEmitsDisconnected() async {
        let task = SessionTestWebSocketTask()
        let session = URLSessionWebSocketSession(task: task)
        let stream = await session.observeState()
        var iterator = stream.makeAsyncIterator()

        await session.disconnect()

        let disconnected = await iterator.next()
        XCTAssertTrue(task.didCancel)
        XCTAssertEqual(disconnected, .disconnected)
    }

    func testSendStringDelegatesToTask() async throws {
        let task = SessionTestWebSocketTask()
        let session = URLSessionWebSocketSession(task: task)

        try await session.sendString("message-json")

        XCTAssertEqual(task.sentStrings, ["message-json"])
    }

    func testSendFailureThrowsAndEmitsFailed() async {
        let task = SessionTestWebSocketTask()
        task.shouldFailSend = true
        let session = URLSessionWebSocketSession(task: task)
        let stream = await session.observeState()
        var iterator = stream.makeAsyncIterator()

        do {
            try await session.sendString("message-json")
            XCTFail("Expected SessionTestWebSocketTaskError.sendFailed")
        } catch let error as SessionTestWebSocketTaskError {
            XCTAssertEqual(error, .sendFailed)
        } catch {
            XCTFail("Expected SessionTestWebSocketTaskError.sendFailed, got \(error)")
        }

        let failed = await iterator.next()
        XCTAssertEqual(failed, .failed)
    }

    func testReceiveStringDelegatesToTask() async throws {
        let task = SessionTestWebSocketTask(incomingStrings: ["incoming-json"])
        let session = URLSessionWebSocketSession(task: task)

        let receivedString = try await session.receiveString()

        XCTAssertEqual(receivedString, "incoming-json")
    }

    func testReceiveFailureThrowsAndEmitsFailed() async {
        let task = SessionTestWebSocketTask()
        task.shouldFailReceive = true
        let session = URLSessionWebSocketSession(task: task)
        let stream = await session.observeState()
        var iterator = stream.makeAsyncIterator()

        do {
            _ = try await session.receiveString()
            XCTFail("Expected SessionTestWebSocketTaskError.receiveFailed")
        } catch let error as SessionTestWebSocketTaskError {
            XCTAssertEqual(error, .receiveFailed)
        } catch {
            XCTFail("Expected SessionTestWebSocketTaskError.receiveFailed, got \(error)")
        }

        let failed = await iterator.next()
        XCTAssertEqual(failed, .failed)
    }

    func testObserveStateReceivesExpectedStateEvents() async throws {
        let task = SessionTestWebSocketTask()
        let session = URLSessionWebSocketSession(task: task)
        let stream = await session.observeState()
        var iterator = stream.makeAsyncIterator()

        try await session.connect()
        await session.disconnect()

        let states = [
            await iterator.next(),
            await iterator.next(),
            await iterator.next()
        ]
        XCTAssertEqual(states, [.connecting, .connected, .disconnected])
    }
}

private final class SessionTestWebSocketTask: WebSocketTaskProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var incomingStrings: [String]
    private var _resumeCallCount = 0
    private var _cancelCallCount = 0
    private var _sentStrings: [String] = []
    private var _shouldFailSend = false
    private var _shouldFailReceive = false

    var didResume: Bool {
        lock.withLock {
            _resumeCallCount > 0
        }
    }

    var didCancel: Bool {
        lock.withLock {
            _cancelCallCount > 0
        }
    }

    var sentStrings: [String] {
        lock.withLock {
            _sentStrings
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

    func resume() {
        lock.withLock {
            _resumeCallCount += 1
        }
    }

    func cancel() {
        lock.withLock {
            _cancelCallCount += 1
        }
    }

    func sendString(_ text: String) async throws {
        let shouldFailSend = lock.withLock {
            _shouldFailSend
        }

        if shouldFailSend {
            throw SessionTestWebSocketTaskError.sendFailed
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
            throw SessionTestWebSocketTaskError.receiveFailed
        }

        return try lock.withLock {
            guard !incomingStrings.isEmpty else {
                throw SessionTestWebSocketTaskError.noIncomingString
            }

            return incomingStrings.removeFirst()
        }
    }
}

private enum SessionTestWebSocketTaskError: Error, Equatable {
    case sendFailed
    case receiveFailed
    case noIncomingString
}
