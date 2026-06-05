import Foundation

protocol WebSocketTaskFactoryProtocol {
    func makeTask(url: URL) -> WebSocketTaskProtocol
}

final class URLSessionWebSocketTaskFactory: WebSocketTaskFactoryProtocol {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func makeTask(url: URL) -> WebSocketTaskProtocol {
        URLSessionWebSocketTaskAdapter(task: session.webSocketTask(with: url))
    }
}
