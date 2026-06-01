import Foundation

public actor JSONIdentityStore: IdentityStore {
    private let fileURL: URL
    private var payload: Payload

    public init(fileURL: URL) {
        self.fileURL = fileURL
        self.payload = Self.loadPayload(from: fileURL)
    }

    public func hasIdentity() async -> Bool {
        payload.identity != nil
    }

    public func saveIdentity(_ identity: UserIdentity, privateKeyData: Data) async throws {
        payload = Payload(identity: identity, privateKeyData: privateKeyData)
        try persistPayload()
    }

    public func loadIdentity() async throws -> UserIdentity {
        guard let identity = payload.identity else {
            throw IdentityError.identityNotFound
        }

        return identity
    }

    public func loadPrivateKeyData() async throws -> Data {
        guard let privateKeyData = payload.privateKeyData else {
            throw IdentityError.privateKeyNotFound
        }

        return privateKeyData
    }

    private func persistPayload() throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let data = try Self.makeEncoder().encode(payload)
        try data.write(to: fileURL, options: .atomic)
    }

    private static func loadPayload(from fileURL: URL) -> Payload {
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let payload = try? makeDecoder().decode(Payload.self, from: data) else {
            return Payload(identity: nil, privateKeyData: nil)
        }

        return payload
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private struct Payload: Codable {
        let identity: UserIdentity?
        let privateKeyData: Data?
    }
}
