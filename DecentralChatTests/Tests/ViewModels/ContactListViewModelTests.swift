import XCTest
import DecentralChatCore
@testable import DecentralChat

@MainActor
final class ContactListViewModelTests: XCTestCase {
    func testLoadContactsShowsSavedContacts() async throws {
        let fixture = makeContactListFixture()
        let contact = makeContactListContact(displayName: "Alice", publicKey: "alice-public-key")
        try await fixture.contactStore.save(contact)
        let viewModel = ContactListViewModel(container: fixture.container)

        await viewModel.loadContacts()

        XCTAssertTrue(viewModel.contacts.contains(contact))
        XCTAssertTrue(viewModel.chatItems.contains { $0.contact.publicKey == contact.publicKey })
        XCTAssertEqual(chatItem(for: contact, in: viewModel)?.title, "Alice")
        XCTAssertEqual(chatItem(for: contact, in: viewModel)?.subtitle, "Tap to chat")
    }

    func testLoadContactsReflectsEditedDisplayName() async throws {
        let fixture = makeContactListFixture()
        let contact = makeContactListContact(displayName: "Alice", publicKey: "alice-public-key")
        let updatedContact = makeContactListContact(
            id: contact.id,
            displayName: "Alice Smith",
            publicKey: contact.publicKey,
            createdAt: contact.createdAt,
            updatedAt: Date(timeIntervalSince1970: 2_000)
        )
        try await fixture.contactStore.save(contact)
        try await fixture.contactStore.save(updatedContact)
        let viewModel = ContactListViewModel(container: fixture.container)

        await viewModel.loadContacts()

        XCTAssertEqual(chatItem(for: contact, in: viewModel)?.title, "Alice Smith")
        XCTAssertEqual(viewModel.contacts.first { $0.publicKey == contact.publicKey }?.displayName, "Alice Smith")
    }

    func testLoadContactsReflectsDeletedContactAndKeepsDebugSeedContact() async throws {
        let fixture = makeContactListFixture()
        let contact = makeContactListContact(displayName: "Alice", publicKey: "alice-public-key")
        try await fixture.contactStore.save(contact)
        try await fixture.contactStore.deleteContact(id: contact.id)
        let viewModel = ContactListViewModel(container: fixture.container)

        await viewModel.loadContacts()

        XCTAssertFalse(viewModel.contacts.contains { $0.publicKey == contact.publicKey })
        XCTAssertFalse(viewModel.chatItems.contains { $0.contact.publicKey == contact.publicKey })
        XCTAssertTrue(viewModel.contacts.contains { $0.publicKey == "demo-contact-public-key" })
    }

    func testLoadContactsShowsLatestMessagePreviewAndStatus() async throws {
        let fixture = makeContactListFixture()
        let contact = makeContactListContact(displayName: "Alice", publicKey: "alice-public-key")
        let olderMessage = makeMessage(
            id: "message-1",
            body: "Older message",
            status: .sent,
            createdAt: Date(timeIntervalSince1970: 2_000),
            contact: contact
        )
        let latestMessage = makeMessage(
            id: "message-2",
            body: "Latest message",
            status: .failed,
            createdAt: Date(timeIntervalSince1970: 3_000),
            contact: contact
        )
        try await fixture.contactStore.save(contact)
        try await fixture.messageStore.save(olderMessage)
        try await fixture.messageStore.save(latestMessage)
        let viewModel = ContactListViewModel(container: fixture.container)

        await viewModel.loadContacts()

        let item = chatItem(for: contact, in: viewModel)
        XCTAssertEqual(item?.subtitle, "Latest message")
        XCTAssertEqual(item?.statusText, MessageStatus.failed.rawValue)
        XCTAssertFalse(item?.timeText.isEmpty ?? true)
    }

    func testLoadContactsAutoCreatesDebugDemoContactWhenStoreIsEmpty() async {
        let fixture = makeContactListFixture()
        let viewModel = ContactListViewModel(container: fixture.container)

        await viewModel.loadContacts()

        XCTAssertEqual(viewModel.contacts.count, 1)
        XCTAssertEqual(viewModel.contacts.first?.displayName, "Demo Contact")
        XCTAssertEqual(viewModel.chatItems.first?.title, "Demo Contact")
        XCTAssertEqual(viewModel.chatItems.first?.subtitle, "Tap to chat")
    }

    func testLoadContactsUsesCurrentDebugContactSortOrder() async throws {
        let fixture = makeContactListFixture()
        let charlie = makeContactListContact(displayName: "Charlie", publicKey: "charlie-public-key")
        let alice = makeContactListContact(displayName: "Alice", publicKey: "alice-public-key")
        try await fixture.contactStore.save(charlie)
        try await fixture.contactStore.save(alice)
        let viewModel = ContactListViewModel(container: fixture.container)

        await viewModel.loadContacts()

        XCTAssertEqual(viewModel.chatItems.map(\.title), ["Alice", "Charlie", "Demo Contact"])
    }
}

private struct ContactListViewModelTestFixture {
    let contactStore: InMemoryContactStore
    let messageStore: InMemoryMessageStore
    let identityStore: InMemoryIdentityStore
    let transport: MockTransport
    let cryptoService: MockCryptoService
    let container: AppContainer
}

@MainActor
private func makeContactListFixture() -> ContactListViewModelTestFixture {
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

    return ContactListViewModelTestFixture(
        contactStore: contactStore,
        messageStore: messageStore,
        identityStore: identityStore,
        transport: transport,
        cryptoService: cryptoService,
        container: container
    )
}

private func makeContactListContact(
    id: String = "contact-id",
    displayName: String,
    publicKey: String,
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

private func makeMessage(
    id: String,
    body: String,
    status: MessageStatus,
    createdAt: Date,
    contact: Contact
) -> ChatMessage {
    ChatMessage(
        id: id,
        conversationID: ConversationIDFactory.makeConversationID(
            publicKeyA: "demo-user-public-key",
            publicKeyB: contact.publicKey
        ),
        senderPublicKey: "demo-user-public-key",
        receiverPublicKey: contact.publicKey,
        body: body,
        createdAt: createdAt,
        status: status,
        direction: .outgoing
    )
}

@MainActor
private func chatItem(
    for contact: Contact,
    in viewModel: ContactListViewModel
) -> ChatListItemViewModel? {
    viewModel.chatItems.first { $0.contact.publicKey == contact.publicKey }
}
