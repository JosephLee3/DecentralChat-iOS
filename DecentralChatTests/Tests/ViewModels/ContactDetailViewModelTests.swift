import XCTest
import DecentralChatCore
@testable import DecentralChat

@MainActor
final class ContactDetailViewModelTests: XCTestCase {
    func testBeginEditingPopulatesDisplayNameAndClearsError() {
        let fixture = makeFixture()
        let contact = makeContact(displayName: "Alice")
        let viewModel = ContactDetailViewModel(contact: contact, container: fixture.container)

        viewModel.editableDisplayName = "Draft"
        viewModel.editErrorMessage = "Existing error"

        viewModel.beginEditing()

        XCTAssertEqual(viewModel.editableDisplayName, "Alice")
        XCTAssertNil(viewModel.editErrorMessage)
    }

    func testSaveDisplayNameEditWithValidNameTrimsAndUpdatesContact() async throws {
        let fixture = makeFixture()
        let createdAt = Date(timeIntervalSince1970: 1_000)
        let contact = makeContact(
            id: "alice-id",
            displayName: "Alice",
            publicKey: "alice-public-key",
            createdAt: createdAt,
            updatedAt: createdAt
        )
        try await fixture.contactStore.save(contact)
        let viewModel = ContactDetailViewModel(contact: contact, container: fixture.container)

        viewModel.editableDisplayName = "  Alice Smith  "
        let didSave = await viewModel.saveDisplayNameEdit()

        let storedContact = try await fixture.contactStore.find(publicKey: contact.publicKey)
        XCTAssertTrue(didSave)
        XCTAssertEqual(storedContact?.displayName, "Alice Smith")
        XCTAssertEqual(viewModel.contact.displayName, "Alice Smith")
        XCTAssertEqual(viewModel.contact.id, contact.id)
        XCTAssertEqual(viewModel.contact.publicKey, contact.publicKey)
        XCTAssertEqual(viewModel.contact.createdAt, createdAt)
        XCTAssertGreaterThanOrEqual(viewModel.contact.updatedAt, createdAt)
        XCTAssertNil(viewModel.editErrorMessage)
    }

    func testSaveDisplayNameEditWithWhitespaceNameFailsAndPreservesStoredContact() async throws {
        let fixture = makeFixture()
        let contact = makeContact(displayName: "Alice")
        try await fixture.contactStore.save(contact)
        let viewModel = ContactDetailViewModel(contact: contact, container: fixture.container)

        viewModel.editableDisplayName = "   "
        let didSave = await viewModel.saveDisplayNameEdit()

        let storedContact = try await fixture.contactStore.find(publicKey: contact.publicKey)
        XCTAssertFalse(didSave)
        XCTAssertNotNil(viewModel.editErrorMessage)
        XCTAssertEqual(storedContact?.displayName, "Alice")
        XCTAssertEqual(viewModel.contact.displayName, "Alice")
    }

    func testSaveDisplayNameEditWithSameTrimmedNameSucceedsWithoutChangingDisplayName() async throws {
        let fixture = makeFixture()
        let contact = makeContact(displayName: "Alice")
        try await fixture.contactStore.save(contact)
        let viewModel = ContactDetailViewModel(contact: contact, container: fixture.container)

        viewModel.editableDisplayName = "  Alice  "
        let didSave = await viewModel.saveDisplayNameEdit()

        let storedContact = try await fixture.contactStore.find(publicKey: contact.publicKey)
        XCTAssertTrue(didSave)
        XCTAssertEqual(storedContact?.displayName, "Alice")
        XCTAssertEqual(viewModel.contact.displayName, "Alice")
        XCTAssertNil(viewModel.editErrorMessage)
    }

    func testDeleteContactRemovesContactAndDoesNotDeleteMessages() async throws {
        let fixture = makeFixture()
        let contact = makeContact(publicKey: "alice-public-key")
        let message = ChatMessage(
            id: "message-1",
            conversationID: "conversation-1",
            senderPublicKey: "demo-user-public-key",
            receiverPublicKey: contact.publicKey,
            body: "Hello",
            createdAt: Date(timeIntervalSince1970: 2_000),
            status: .sent,
            direction: .outgoing
        )
        try await fixture.contactStore.save(contact)
        try await fixture.messageStore.save(message)
        let viewModel = ContactDetailViewModel(contact: contact, container: fixture.container)

        let didDelete = await viewModel.deleteContact()

        let storedContact = try await fixture.contactStore.find(publicKey: contact.publicKey)
        let storedMessages = try await fixture.messageStore.messages(conversationID: message.conversationID)
        XCTAssertTrue(didDelete)
        XCTAssertNil(storedContact)
        XCTAssertEqual(storedMessages, [message])
        XCTAssertNil(viewModel.deleteErrorMessage)
    }
}

private struct ContactDetailViewModelTestFixture {
    let contactStore: InMemoryContactStore
    let messageStore: InMemoryMessageStore
    let identityStore: InMemoryIdentityStore
    let transport: MockTransport
    let cryptoService: MockCryptoService
    let container: AppContainer
}

@MainActor
private func makeFixture() -> ContactDetailViewModelTestFixture {
    let contactStore = InMemoryContactStore()
    let messageStore = InMemoryMessageStore()
    let identityStore = InMemoryIdentityStore()
    let transport = MockTransport()
    let cryptoService = MockCryptoService()
    let container = try! AppContainer(
        messageStore: messageStore,
        identityStore: identityStore,
        contactStore: contactStore,
        transport: transport,
        cryptoService: cryptoService
    )

    return ContactDetailViewModelTestFixture(
        contactStore: contactStore,
        messageStore: messageStore,
        identityStore: identityStore,
        transport: transport,
        cryptoService: cryptoService,
        container: container
    )
}

private func makeContact(
    id: String = "contact-id",
    displayName: String = "Alice",
    publicKey: String = "contact-public-key",
    createdAt: Date = Date(timeIntervalSince1970: 1_000),
    updatedAt: Date = Date(timeIntervalSince1970: 1_000)
) -> Contact {
    Contact(
        id: id,
        displayName: displayName,
        publicKey: publicKey,
        avatarURLString: nil,
        createdAt: createdAt,
        updatedAt: updatedAt
    )
}
