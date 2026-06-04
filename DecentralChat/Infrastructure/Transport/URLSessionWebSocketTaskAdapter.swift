import Foundation

final class URLSessionWebSocketTaskAdapter: WebSocketTaskProtocol {
    private let task: URLSessionWebSocketTask

    init(task: URLSessionWebSocketTask) {
        self.task = task
    }

    func resume() {
        task.resume()
    }

    func cancel() {
        task.cancel(with: .goingAway, reason: nil)
    }

    func sendString(_ text: String) async throws {
        try await task.send(.string(text))
    }

    func receiveString() async throws -> String {
        let message = try await task.receive()

        switch message {
        case .string(let text):
            return text
        case .data(let data):
            guard let text = String(data: data, encoding: .utf8) else {
                throw URLSessionWebSocketTaskAdapterError.invalidUTF8Payload
            }

            return text
        @unknown default:
            throw URLSessionWebSocketTaskAdapterError.unsupportedMessage
        }
    }
}

enum URLSessionWebSocketTaskAdapterError: Error {
    case invalidUTF8Payload
    case unsupportedMessage
}
