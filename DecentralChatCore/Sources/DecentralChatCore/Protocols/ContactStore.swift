import Foundation

public protocol ContactStore {
    func save(_ contact: Contact) async throws
    func contacts() async throws -> [Contact]
    func find(publicKey: String) async throws -> Contact?
    func deleteContact(id: String) async throws
}
