import DecentralChatCore
import Foundation
import XCTest

final class JSONIdentityStoreTests: XCTestCase {
    func testHasIdentityIsFalseWhenFileIsMissing() async {
        let store = JSONIdentityStore(fileURL: makeTemporaryFileURL())

        let hasIdentity = await store.hasIdentity()

        XCTAssertFalse(hasIdentity)
    }

    func testSaveIdentityAndPrivateKeyPersistAcrossStoreRecreation() async throws {
        let fileURL = makeTemporaryFileURL()
        let identity = makeIdentity(id: "identity-1", displayName: "Alice", publicKey: "alice-public-key")
        let privateKeyData = Data([1, 2, 3])
        let store = JSONIdentityStore(fileURL: fileURL)

        try await store.saveIdentity(identity, privateKeyData: privateKeyData)

        let recreatedStore = JSONIdentityStore(fileURL: fileURL)
        let loadedIdentity = try await recreatedStore.loadIdentity()
        let loadedPrivateKeyData = try await recreatedStore.loadPrivateKeyData()
        let hasIdentity = await recreatedStore.hasIdentity()

        XCTAssertTrue(hasIdentity)
        XCTAssertEqual(loadedIdentity, identity)
        XCTAssertEqual(loadedPrivateKeyData, privateKeyData)
    }

    func testLoadIdentityThrowsIdentityNotFoundWhenEmpty() async {
        let store = JSONIdentityStore(fileURL: makeTemporaryFileURL())

        do {
            _ = try await store.loadIdentity()
            XCTFail("Expected IdentityError.identityNotFound")
        } catch let error as IdentityError {
            XCTAssertEqual(error, .identityNotFound)
        } catch {
            XCTFail("Expected IdentityError.identityNotFound, got \(error)")
        }
    }

    func testLoadPrivateKeyDataThrowsPrivateKeyNotFoundWhenEmpty() async {
        let store = JSONIdentityStore(fileURL: makeTemporaryFileURL())

        do {
            _ = try await store.loadPrivateKeyData()
            XCTFail("Expected IdentityError.privateKeyNotFound")
        } catch let error as IdentityError {
            XCTAssertEqual(error, .privateKeyNotFound)
        } catch {
            XCTFail("Expected IdentityError.privateKeyNotFound, got \(error)")
        }
    }

    func testOverwriteIdentityAndPrivateKeyPersistsLatestValues() async throws {
        let fileURL = makeTemporaryFileURL()
        let store = JSONIdentityStore(fileURL: fileURL)
        let originalIdentity = makeIdentity(id: "identity-1", displayName: "Alice", publicKey: "alice-public-key")
        let updatedIdentity = makeIdentity(id: "identity-2", displayName: "Bob", publicKey: "bob-public-key")
        let updatedPrivateKeyData = Data([4, 5, 6])

        try await store.saveIdentity(originalIdentity, privateKeyData: Data([1, 2, 3]))
        try await store.saveIdentity(updatedIdentity, privateKeyData: updatedPrivateKeyData)

        let recreatedStore = JSONIdentityStore(fileURL: fileURL)
        let loadedIdentity = try await recreatedStore.loadIdentity()
        let loadedPrivateKeyData = try await recreatedStore.loadPrivateKeyData()

        XCTAssertEqual(loadedIdentity, updatedIdentity)
        XCTAssertEqual(loadedPrivateKeyData, updatedPrivateKeyData)
    }

    func testDateFieldsSurviveReload() async throws {
        let fileURL = makeTemporaryFileURL()
        let createdAt = Date(timeIntervalSince1970: 100)
        let identity = UserIdentity(
            id: "identity-1",
            displayName: "Alice",
            publicKey: "alice-public-key",
            createdAt: createdAt
        )
        let store = JSONIdentityStore(fileURL: fileURL)

        try await store.saveIdentity(identity, privateKeyData: Data([1, 2, 3]))

        let recreatedStore = JSONIdentityStore(fileURL: fileURL)
        let loadedIdentity = try await recreatedStore.loadIdentity()
        XCTAssertEqual(loadedIdentity.createdAt, createdAt)
    }

    private func makeTemporaryFileURL() -> URL {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)

        addTeardownBlock {
            try? FileManager.default.removeItem(at: directoryURL)
        }

        return directoryURL.appendingPathComponent("identity.json")
    }

    private func makeIdentity(id: String, displayName: String, publicKey: String) -> UserIdentity {
        UserIdentity(
            id: id,
            displayName: displayName,
            publicKey: publicKey,
            createdAt: Date(timeIntervalSince1970: 100)
        )
    }
}
