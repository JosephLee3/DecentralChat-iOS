import Foundation
import XCTest
@testable import DecentralChat

final class URLSessionWebSocketTaskFactoryTests: XCTestCase {
    func testFakeFactoryRecordsRequestedURL() throws {
        let factory = FakeWebSocketTaskFactory()
        let url = try XCTUnwrap(URL(string: "wss://relay.example.com/chat"))

        _ = factory.makeTask(url: url)

        XCTAssertEqual(factory.requestedURLs, [url])
    }

    func testFakeFactoryReturnsFakeWebSocketTaskProtocol() throws {
        let task = FakeFactoryWebSocketTask()
        let factory = FakeWebSocketTaskFactory(task: task)
        let url = try XCTUnwrap(URL(string: "wss://relay.example.com/chat"))

        let returnedTask = factory.makeTask(url: url)

        XCTAssertTrue(returnedTask as? FakeFactoryWebSocketTask === task)
    }

    func testReturnedFakeTaskCanBeUsedWithoutLiveNetwork() async throws {
        let task = FakeFactoryWebSocketTask(incomingStrings: ["incoming-json"])
        let factory = FakeWebSocketTaskFactory(task: task)
        let url = try XCTUnwrap(URL(string: "wss://relay.example.com/chat"))
        let returnedTask = factory.makeTask(url: url)

        returnedTask.resume()
        try await returnedTask.sendString("outgoing-json")
        let receivedString = try await returnedTask.receiveString()
        returnedTask.cancel()

        XCTAssertEqual(task.resumeCallCount, 1)
        XCTAssertEqual(task.sentStrings, ["outgoing-json"])
        XCTAssertEqual(receivedString, "incoming-json")
        XCTAssertEqual(task.cancelCallCount, 1)
    }
}

private final class FakeWebSocketTaskFactory: WebSocketTaskFactoryProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private let task: WebSocketTaskProtocol
    private var _requestedURLs: [URL] = []

    var requestedURLs: [URL] {
        lock.withLock {
            _requestedURLs
        }
    }

    init(task: WebSocketTaskProtocol = FakeFactoryWebSocketTask()) {
        self.task = task
    }

    func makeTask(url: URL) -> WebSocketTaskProtocol {
        lock.withLock {
            _requestedURLs.append(url)
        }

        return task
    }
}

private final class FakeFactoryWebSocketTask: WebSocketTaskProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var incomingStrings: [String]
    private var _resumeCallCount = 0
    private var _cancelCallCount = 0
    private var _sentStrings: [String] = []

    var resumeCallCount: Int {
        lock.withLock {
            _resumeCallCount
        }
    }

    var cancelCallCount: Int {
        lock.withLock {
            _cancelCallCount
        }
    }

    var sentStrings: [String] {
        lock.withLock {
            _sentStrings
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
        lock.withLock {
            _sentStrings.append(text)
        }
    }

    func receiveString() async throws -> String {
        try lock.withLock {
            guard !incomingStrings.isEmpty else {
                throw FakeFactoryWebSocketTaskError.noIncomingString
            }

            return incomingStrings.removeFirst()
        }
    }
}

private enum FakeFactoryWebSocketTaskError: Error {
    case noIncomingString
}
