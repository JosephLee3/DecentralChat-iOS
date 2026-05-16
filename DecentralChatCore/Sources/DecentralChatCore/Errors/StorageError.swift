public enum StorageError: Error, Equatable {
    case notFound
    case duplicate
    case saveFailed
    case updateFailed
}
