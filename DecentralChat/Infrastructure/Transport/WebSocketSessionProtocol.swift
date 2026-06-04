import DecentralChatCore
import Foundation

protocol WebSocketSessionProtocol {
    func connect() async throws
    func disconnect() async
    func sendString(_ text: String) async throws
    func receiveString() async throws -> String
    func observeState() -> AsyncStream<TransportState>
}
