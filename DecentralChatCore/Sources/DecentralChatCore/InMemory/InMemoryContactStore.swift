import Foundation

public actor InMemoryContactStore: ContactStore {
    private var contactsByPublicKey: [String: Contact]

    public init(contacts: [Contact] = []) {
        self.contactsByPublicKey = Dictionary(uniqueKeysWithValues: contacts.map { ($0.publicKey, $0) })
    }

    public func save(_ contact: Contact) async throws {
        contactsByPublicKey[contact.publicKey] = contact
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
    }
}
