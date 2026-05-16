import Foundation

public protocol ChatTransport {
    func connect() async throws
    func disconnect() async
    func send(_ envelope: MessageEnvelope) async throws
    func observeIncomingMessages() -> AsyncStream<MessageEnvelope>
    func observeState() -> AsyncStream<TransportState>
}
