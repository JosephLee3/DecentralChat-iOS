public enum TransportError: Error, Equatable {
    case notConnected
    case sendFailed
    case receiveFailed
}
