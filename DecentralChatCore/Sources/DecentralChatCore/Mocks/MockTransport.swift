import Foundation

public final class MockTransport: ChatTransport {
    private let lock = NSLock()
    private var incomingContinuations: [UUID: AsyncStream<MessageEnvelope>.Continuation] = [:]
    private var stateContinuations: [UUID: AsyncStream<TransportState>.Continuation] = [:]
    private var _sentEnvelopes: [MessageEnvelope] = []
    private var _shouldFailSend = false

    public var sentEnvelopes: [MessageEnvelope] {
        lock.withLock {
            _sentEnvelopes
        }
    }

    public var shouldFailSend: Bool {
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

    public init() {}

    public func connect() async throws {
        simulateState(.connected)
    }

    public func disconnect() async {
        simulateState(.disconnected)
    }

    public func send(_ envelope: MessageEnvelope) async throws {
        let shouldFail = lock.withLock {
            _shouldFailSend
        }

        if shouldFail {
            throw TransportError.sendFailed
        }

        lock.withLock {
            _sentEnvelopes.append(envelope)
        }
    }

    public func observeIncomingMessages() -> AsyncStream<MessageEnvelope> {
        AsyncStream { continuation in
            let id = UUID()

            lock.withLock {
                incomingContinuations[id] = continuation
            }

            continuation.onTermination = { [weak self] _ in
                self?.lock.withLock {
                    self?.incomingContinuations[id] = nil
                }
            }
        }
    }

    public func observeState() -> AsyncStream<TransportState> {
        AsyncStream { continuation in
            let id = UUID()

            continuation.yield(.idle)

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

    public func simulateIncoming(_ envelope: MessageEnvelope) {
        let continuations = lock.withLock {
            Array(incomingContinuations.values)
        }

        continuations.forEach { continuation in
            continuation.yield(envelope)
        }
    }

    public func simulateState(_ state: TransportState) {
        let continuations = lock.withLock {
            Array(stateContinuations.values)
        }

        continuations.forEach { continuation in
            continuation.yield(state)
        }
    }
}
