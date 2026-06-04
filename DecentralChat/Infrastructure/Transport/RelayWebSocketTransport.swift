import DecentralChatCore
import Foundation

final class RelayWebSocketTransport: ChatTransport {
    private let session: WebSocketSessionProtocol
    private let codec: MessageEnvelopeWireCodec

    init(
        session: WebSocketSessionProtocol,
        codec: MessageEnvelopeWireCodec = MessageEnvelopeWireCodec()
    ) {
        self.session = session
        self.codec = codec
    }

    func connect() async throws {
        try await session.connect()
    }

    func disconnect() async {
        await session.disconnect()
    }

    func send(_ envelope: MessageEnvelope) async throws {
        let data = try codec.encode(envelope)

        guard let text = String(data: data, encoding: .utf8) else {
            throw RelayWebSocketTransportError.invalidUTF8Payload
        }

        try await session.sendString(text)
    }

    func observeIncomingMessages() -> AsyncStream<MessageEnvelope> {
        AsyncStream { continuation in
            let task = Task {
                while !Task.isCancelled {
                    do {
                        let text = try await session.receiveString()

                        guard let data = text.data(using: .utf8) else {
                            continue
                        }

                        do {
                            let envelope = try codec.decode(data)
                            continuation.yield(envelope)
                        } catch {
                            continue
                        }
                    } catch {
                        continuation.finish()
                        break
                    }
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    func observeState() -> AsyncStream<TransportState> {
        session.observeState()
    }
}

private enum RelayWebSocketTransportError: Error {
    case invalidUTF8Payload
}
