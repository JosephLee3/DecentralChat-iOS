import DecentralChatCore
import Foundation
import XCTest

final class InMemoryIdentityStoreTests: XCTestCase {
    func testCanSaveAndLoadIdentity() async throws {
        let store = InMemoryIdentityStore()
        let identity = UserIdentity(
            id: "identity-1",
            displayName: "Alice",
            publicKey: "alice-public-key",
            createdAt: Date(timeIntervalSince1970: 100)
        )
        let privateKeyData = Data([1, 2, 3])

        try await store.saveIdentity(identity, privateKeyData: privateKeyData)

        let loadedIdentity = try await store.loadIdentity()
        let loadedPrivateKeyData = try await store.loadPrivateKeyData()
        let hasIdentity = await store.hasIdentity()

        XCTAssertTrue(hasIdentity)
        XCTAssertEqual(loadedIdentity, identity)
        XCTAssertEqual(loadedPrivateKeyData, privateKeyData)
    }

    func testLoadIdentityThrowsIdentityNotFoundWhenEmpty() async {
        let store = InMemoryIdentityStore()

        do {
            _ = try await store.loadIdentity()
            XCTFail("Expected IdentityError.identityNotFound")
        } catch let error as IdentityError {
            XCTAssertEqual(error, .identityNotFound)
        } catch {
            XCTFail("Expected IdentityError.identityNotFound, got \(error)")
        }
    }
}
