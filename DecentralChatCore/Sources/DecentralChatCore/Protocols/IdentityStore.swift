import Foundation

public protocol IdentityStore {
    func hasIdentity() async -> Bool
    func saveIdentity(_ identity: UserIdentity, privateKeyData: Data) async throws
    func loadIdentity() async throws -> UserIdentity
    func loadPrivateKeyData() async throws -> Data
}
