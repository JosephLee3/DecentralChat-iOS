import Foundation

public protocol MessageSyncService {
    func sync() async throws
}
