import DecentralChatCore
import Foundation
import XCTest

final class InMemoryContactStoreTests: XCTestCase {
    func testCanSaveAndFindContact() async throws {
        let store = InMemoryContactStore()
        let contact = makeContact(id: "contact-1", displayName: "Alice", publicKey: "alice-public-key")

        try await store.save(contact)

        let loadedContact = try await store.find(publicKey: contact.publicKey)
        XCTAssertEqual(loadedContact, contact)
    }

    func testContactsAreSortedByDisplayName() async throws {
        let store = InMemoryContactStore()
        let zed = makeContact(id: "contact-1", displayName: "Zed", publicKey: "zed-public-key")
        let alice = makeContact(id: "contact-2", displayName: "Alice", publicKey: "alice-public-key")
        let bob = makeContact(id: "contact-3", displayName: "Bob", publicKey: "bob-public-key")

        try await store.save(zed)
        try await store.save(alice)
        try await store.save(bob)

        let contacts = try await store.contacts()
        XCTAssertEqual(contacts.map(\.displayName), ["Alice", "Bob", "Zed"])
    }

    private func makeContact(id: String, displayName: String, publicKey: String) -> Contact {
        Contact(
            id: id,
            displayName: displayName,
            publicKey: publicKey,
            createdAt: Date(timeIntervalSince1970: 100)
        )
    }
}
