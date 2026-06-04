import Foundation
import XCTest
@testable import DecentralChat

final class FakeWebSocketTaskTests: XCTestCase {
    func testResumeRecordsThatTaskResumed() {
        let task = FakeWebSocketTask()

        task.resume()

        XCTAssertEqual(task.resumeCallCount, 1)
        XCTAssertTrue(task.didResume)
    }

    func testCancelRecordsThatTaskCancelled() {
        let task = FakeWebSocketTask()

        task.cancel()

        XCTAssertEqual(task.cancelCallCount, 1)
        XCTAssertTrue(task.didCancel)
    }

    func testSendStringRecordsOutgoingString() async throws {
        let task = FakeWebSocketTask()

        try await task.sendString("message-json")

        XCTAssertEqual(task.sentStrings, ["message-json"])
    }

    func testSendStringFailureThrows() async {
        let task = FakeWebSocketTask()
        task.shouldFailSend = true

        do {
            try await task.sendString("message-json")
            XCTFail("Expected FakeWebSocketTaskError.sendFailed")
        } catch let error as FakeWebSocketTaskError {
            XCTAssertEqual(error, .sendFailed)
        } catch {
            XCTFail("Expected FakeWebSocketTaskError.sendFailed, got \(error)")
        }
    }

    func testReceiveStringReturnsQueuedIncomingStringsInOrder() async throws {
        let task = FakeWebSocketTask(incomingStrings: ["first-json", "second-json"])

        let first = try await task.receiveString()
        let second = try await task.receiveString()

        XCTAssertEqual(first, "first-json")
        XCTAssertEqual(second, "second-json")
    }

    func testReceiveStringFailureThrows() async {
        let task = FakeWebSocketTask(incomingStrings: ["message-json"])
        task.shouldFailReceive = true

        do {
            _ = try await task.receiveString()
            XCTFail("Expected FakeWebSocketTaskError.receiveFailed")
        } catch let error as FakeWebSocketTaskError {
            XCTAssertEqual(error, .receiveFailed)
        } catch {
            XCTFail("Expected FakeWebSocketTaskError.receiveFailed, got \(error)")
        }
    }

    func testReceiveStringWithEmptyQueueThrowsNoIncomingString() async {
        let task = FakeWebSocketTask()

        do {
            _ = try await task.receiveString()
            XCTFail("Expected FakeWebSocketTaskError.noIncomingString")
        } catch let error as FakeWebSocketTaskError {
            XCTAssertEqual(error, .noIncomingString)
        } catch {
            XCTFail("Expected FakeWebSocketTaskError.noIncomingString, got \(error)")
        }
    }
}

private final class FakeWebSocketTask: WebSocketTaskProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var incomingStrings: [String]
    private var _resumeCallCount = 0
    private var _cancelCallCount = 0
    private var _sentStrings: [String] = []
    private var _shouldFailSend = false
    private var _shouldFailReceive = false

    var resumeCallCount: Int {
        lock.withLock {
            _resumeCallCount
        }
    }

    var didResume: Bool {
        resumeCallCount > 0
    }

    var cancelCallCount: Int {
        lock.withLock {
            _cancelCallCount
        }
    }

    var didCancel: Bool {
        cancelCallCount > 0
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
            throw FakeWebSocketTaskError.sendFailed
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
            throw FakeWebSocketTaskError.receiveFailed
        }

        return try lock.withLock {
            guard !incomingStrings.isEmpty else {
                throw FakeWebSocketTaskError.noIncomingString
            }

            return incomingStrings.removeFirst()
        }
    }
}

private enum FakeWebSocketTaskError: Error, Equatable {
    case sendFailed
    case receiveFailed
    case noIncomingString
}
