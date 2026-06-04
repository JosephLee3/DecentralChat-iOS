import XCTest
import DecentralChatCore
@testable import DecentralChat

@MainActor
final class ChatRoomViewModelTests: XCTestCase {
    func testSendSuccessReloadsMessagesAndClearsInputText() async throws {
        let fixture = makeChatRoomFixture()
        let contact = makeChatRoomContact()
        let viewModel = ChatRoomViewModel(container: fixture.container, contact: contact)

        viewModel.inputText = "Hello"
        await viewModel.send()

        XCTAssertEqual(viewModel.messages.count, 1)
        XCTAssertEqual(viewModel.messages.first?.body, "Hello")
        XCTAssertEqual(viewModel.messages.first?.status, .sent)
        XCTAssertEqual(viewModel.inputText, "")
        XCTAssertNil(viewModel.errorMessage)
    }

    func testSendFailureReloadsFailedMessageAndKeepsInputText() async throws {
        let fixture = makeChatRoomFixture()
        let contact = makeChatRoomContact()
        let viewModel = ChatRoomViewModel(container: fixture.container, contact: contact)

        fixture.transport.shouldFailSend = true
        viewModel.inputText = "Hello"
        await viewModel.send()

        XCTAssertEqual(viewModel.messages.count, 1)
        XCTAssertEqual(viewModel.messages.first?.body, "Hello")
        XCTAssertEqual(viewModel.messages.first?.direction, .outgoing)
        XCTAssertEqual(viewModel.messages.first?.status, .failed)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.inputText, "Hello")
    }

    func testRetrySuccessReloadsMessagesAndDoesNotCreateDuplicate() async throws {
        let fixture = makeChatRoomFixture()
        let contact = makeChatRoomContact()
        let failedMessage = makeFailedOutgoingMessage(contact: contact)
        try await fixture.messageStore.save(failedMessage)
        let viewModel = ChatRoomViewModel(container: fixture.container, contact: contact)

        await viewModel.reloadMessages()
        fixture.transport.shouldFailSend = false
        await viewModel.retry(message: failedMessage)

        XCTAssertEqual(viewModel.messages.count, 1)
        XCTAssertEqual(viewModel.messages.first?.id, failedMessage.id)
        XCTAssertEqual(viewModel.messages.first?.status, .sent)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testRetryFailureReloadsMessagesAndDoesNotCreateDuplicate() async throws {
        let fixture = makeChatRoomFixture()
        let contact = makeChatRoomContact()
        let failedMessage = makeFailedOutgoingMessage(contact: contact)
        try await fixture.messageStore.save(failedMessage)
        let viewModel = ChatRoomViewModel(container: fixture.container, contact: contact)

        await viewModel.reloadMessages()
        fixture.transport.shouldFailSend = true
        await viewModel.retry(message: failedMessage)

        XCTAssertEqual(viewModel.messages.count, 1)
        XCTAssertEqual(viewModel.messages.first?.id, failedMessage.id)
        XCTAssertEqual(viewModel.messages.first?.status, .failed)
        XCTAssertNotNil(viewModel.errorMessage)
    }
}

private struct ChatRoomViewModelTestFixture {
    let contactStore: InMemoryContactStore
    let messageStore: InMemoryMessageStore
    let identityStore: InMemoryIdentityStore
    let transport: MockTransport
    let cryptoService: MockCryptoService
    let container: AppContainer
}

@MainActor
private func makeChatRoomFixture() -> ChatRoomViewModelTestFixture {
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

    return ChatRoomViewModelTestFixture(
        contactStore: contactStore,
        messageStore: messageStore,
        identityStore: identityStore,
        transport: transport,
        cryptoService: cryptoService,
        container: container
    )
}

private func makeChatRoomContact(
    id: String = "contact-id",
    displayName: String = "Alice",
    publicKey: String = "alice-public-key"
) -> Contact {
    Contact(
        id: id,
        displayName: displayName,
        publicKey: publicKey,
        createdAt: Date(timeIntervalSince1970: 1_000)
    )
}

private func makeFailedOutgoingMessage(contact: Contact) -> ChatMessage {
    ChatMessage(
        id: "failed-message-1",
        conversationID: ConversationIDFactory.makeConversationID(
            publicKeyA: "demo-user-public-key",
            publicKeyB: contact.publicKey
        ),
        senderPublicKey: "demo-user-public-key",
        receiverPublicKey: contact.publicKey,
        body: "Retry me",
        createdAt: Date(timeIntervalSince1970: 2_000),
        status: .failed,
        direction: .outgoing
    )
}
