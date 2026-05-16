import Foundation

public actor InMemoryIdentityStore: IdentityStore {
    private var identity: UserIdentity?
    private var privateKeyData: Data?

    public init(identity: UserIdentity? = nil, privateKeyData: Data? = nil) {
        self.identity = identity
        self.privateKeyData = privateKeyData
    }

    public func hasIdentity() async -> Bool {
        identity != nil
    }

    public func saveIdentity(_ identity: UserIdentity, privateKeyData: Data) async throws {
        self.identity = identity
        self.privateKeyData = privateKeyData
    }

    public func loadIdentity() async throws -> UserIdentity {
        guard let identity else {
            throw IdentityError.identityNotFound
        }

        return identity
    }

    public func loadPrivateKeyData() async throws -> Data {
        guard let privateKeyData else {
            throw IdentityError.privateKeyNotFound
        }

        return privateKeyData
    }
}
