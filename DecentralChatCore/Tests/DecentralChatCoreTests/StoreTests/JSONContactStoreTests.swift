import DecentralChatCore
import Foundation
import XCTest

final class JSONContactStoreTests: XCTestCase {
    func testSaveContactPersistsAcrossStoreRecreation() async throws {
        let fileURL = makeTemporaryFileURL()
        let contact = makeContact(id: "contact-1", displayName: "Alice", publicKey: "alice-public-key")
        let store = JSONContactStore(fileURL: fileURL)

        try await store.save(contact)

        let recreatedStore = JSONContactStore(fileURL: fileURL)
        let loadedContact = try await recreatedStore.find(publicKey: contact.publicKey)
        XCTAssertEqual(loadedContact, contact)
    }

    func testOverwriteSamePublicKeyPersistsUpdatedDisplayName() async throws {
        let fileURL = makeTemporaryFileURL()
        let store = JSONContactStore(fileURL: fileURL)
        let originalContact = makeContact(id: "contact-1", displayName: "Alice", publicKey: "alice-public-key")
        let updatedContact = Contact(
            id: originalContact.id,
            displayName: "Alice Updated",
            publicKey: originalContact.publicKey,
            avatarURLString: originalContact.avatarURLString,
            createdAt: originalContact.createdAt,
            updatedAt: Date(timeIntervalSince1970: 200)
        )

        try await store.save(originalContact)
        try await store.save(updatedContact)

        let recreatedStore = JSONContactStore(fileURL: fileURL)
        let loadedContact = try await recreatedStore.find(publicKey: originalContact.publicKey)
        XCTAssertEqual(loadedContact?.displayName, "Alice Updated")
        XCTAssertEqual(loadedContact, updatedContact)
    }

    func testDeleteContactPersistsAcrossStoreRecreation() async throws {
        let fileURL = makeTemporaryFileURL()
        let store = JSONContactStore(fileURL: fileURL)
        let contact = makeContact(id: "contact-1", displayName: "Alice", publicKey: "alice-public-key")

        try await store.save(contact)
        try await store.deleteContact(id: contact.id)

        let recreatedStore = JSONContactStore(fileURL: fileURL)
        let contacts = try await recreatedStore.contacts()
        XCTAssertTrue(contacts.isEmpty)
    }

    func testDeleteMissingContactDoesNotThrow() async throws {
        let fileURL = makeTemporaryFileURL()
        let store = JSONContactStore(fileURL: fileURL)

        try await store.deleteContact(id: "missing-contact")

        let contacts = try await store.contacts()
        XCTAssertTrue(contacts.isEmpty)
    }

    func testContactsAreSortedByDisplayName() async throws {
        let fileURL = makeTemporaryFileURL()
        let store = JSONContactStore(fileURL: fileURL)
        let zed = makeContact(id: "contact-1", displayName: "Zed", publicKey: "zed-public-key")
        let alice = makeContact(id: "contact-2", displayName: "Alice", publicKey: "alice-public-key")
        let bob = makeContact(id: "contact-3", displayName: "Bob", publicKey: "bob-public-key")

        try await store.save(zed)
        try await store.save(alice)
        try await store.save(bob)

        let recreatedStore = JSONContactStore(fileURL: fileURL)
        let contacts = try await recreatedStore.contacts()
        XCTAssertEqual(contacts.map(\.displayName), ["Alice", "Bob", "Zed"])
    }

    func testDateFieldsSurviveReload() async throws {
        let fileURL = makeTemporaryFileURL()
        let createdAt = Date(timeIntervalSince1970: 100)
        let updatedAt = Date(timeIntervalSince1970: 200)
        let contact = Contact(
            id: "contact-1",
            displayName: "Alice",
            publicKey: "alice-public-key",
            createdAt: createdAt,
            updatedAt: updatedAt
        )
        let store = JSONContactStore(fileURL: fileURL)

        try await store.save(contact)

        let recreatedStore = JSONContactStore(fileURL: fileURL)
        let loadedContact = try await recreatedStore.find(publicKey: contact.publicKey)
        XCTAssertEqual(loadedContact?.createdAt, createdAt)
        XCTAssertEqual(loadedContact?.updatedAt, updatedAt)
    }

    private func makeTemporaryFileURL() -> URL {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)

        addTeardownBlock {
            try? FileManager.default.removeItem(at: directoryURL)
        }

        return directoryURL.appendingPathComponent("contacts.json")
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
