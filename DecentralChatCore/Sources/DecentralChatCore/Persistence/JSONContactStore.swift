import Foundation

public actor JSONContactStore: ContactStore {
    private let fileURL: URL
    private var contactsByPublicKey: [String: Contact]

    public init(fileURL: URL) {
        self.fileURL = fileURL
        self.contactsByPublicKey = Self.loadContactsByPublicKey(from: fileURL)
    }

    public func save(_ contact: Contact) async throws {
        contactsByPublicKey[contact.publicKey] = contact
        try persistContacts()
    }

    public func contacts() async throws -> [Contact] {
        contactsByPublicKey.values.sorted { $0.displayName < $1.displayName }
    }

    public func find(publicKey: String) async throws -> Contact? {
        contactsByPublicKey[publicKey]
    }

    public func deleteContact(id: String) async throws {
        guard let publicKey = contactsByPublicKey.first(where: { $0.value.id == id })?.key else {
            return
        }

        contactsByPublicKey.removeValue(forKey: publicKey)
        try persistContacts()
    }

    private func persistContacts() throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let contacts = contactsByPublicKey.values.sorted { $0.displayName < $1.displayName }
        let data = try Self.makeEncoder().encode(contacts)
        try data.write(to: fileURL, options: .atomic)
    }

    private static func loadContactsByPublicKey(from fileURL: URL) -> [String: Contact] {
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let contacts = try? makeDecoder().decode([Contact].self, from: data) else {
            return [:]
        }

        return Dictionary(uniqueKeysWithValues: contacts.map { ($0.publicKey, $0) })
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
}
