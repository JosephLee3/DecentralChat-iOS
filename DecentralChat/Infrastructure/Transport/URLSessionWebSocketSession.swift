import DecentralChatCore
import Foundation

final class URLSessionWebSocketSession: WebSocketSessionProtocol {
    private let task: WebSocketTaskProtocol
    private let stateContinuations = StateContinuationStore()

    init(task: WebSocketTaskProtocol) {
        self.task = task
    }

    func connect() async throws {
        emitState(.connecting)
        task.resume()
        emitState(.connected)
    }

    func disconnect() async {
        task.cancel()
        emitState(.disconnected)
    }

    func sendString(_ text: String) async throws {
        do {
            try await task.sendString(text)
        } catch {
            emitState(.failed)
            throw error
        }
    }

    func receiveString() async throws -> String {
        do {
            return try await task.receiveString()
        } catch {
            emitState(.failed)
            throw error
        }
    }

    func observeState() -> AsyncStream<TransportState> {
        AsyncStream { continuation in
            let id = UUID()

            stateContinuations.add(continuation, id: id)

            continuation.onTermination = { [stateContinuations] _ in
                stateContinuations.remove(id: id)
            }
        }
    }

    private func emitState(_ state: TransportState) {
        stateContinuations.emit(state)
    }
}

nonisolated private final class StateContinuationStore: @unchecked Sendable {
    private let lock = NSLock()
    private var continuations: [UUID: AsyncStream<TransportState>.Continuation] = [:]

    func add(_ continuation: AsyncStream<TransportState>.Continuation, id: UUID) {
        lock.withLock {
            continuations[id] = continuation
        }
    }

    func remove(id: UUID) {
        lock.withLock {
            continuations[id] = nil
        }
    }

    func emit(_ state: TransportState) {
        let storedContinuations = lock.withLock {
            Array(continuations.values)
        }

        storedContinuations.forEach { continuation in
            continuation.yield(state)
        }
    }
}
