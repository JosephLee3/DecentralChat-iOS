import DecentralChatCore
import Foundation
import XCTest

final class InMemoryMessageStoreTests: XCTestCase {
    func testCanSaveAndLoadMessageByID() async throws {
        let store = InMemoryMessageStore()
        let message = makeMessage(id: "message-1")

        try await store.save(message)

        let loadedMessage = try await store.message(id: message.id)
        XCTAssertEqual(loadedMessage, message)
    }

    func testCanUpdateMessageStatus() async throws {
        let store = InMemoryMessageStore()
        let message = makeMessage(id: "message-1", status: .pending)

        try await store.save(message)
        try await store.updateStatus(message.id, .sent)

        let loadedMessage = try await store.message(id: message.id)
        XCTAssertEqual(loadedMessage?.status, .sent)
    }

    func testExistsReturnsTrueAfterSaving() async throws {
        let store = InMemoryMessageStore()
        let message = makeMessage(id: "message-1")

        try await store.save(message)

        let exists = try await store.exists(messageID: message.id)
        XCTAssertTrue(exists)
    }

    func testMessagesForConversationAreSortedByCreatedAt() async throws {
        let store = InMemoryMessageStore()
        let laterMessage = makeMessage(id: "message-2", conversationID: "conversation-1", createdAt: Date(timeIntervalSince1970: 200))
        let earlierMessage = makeMessage(id: "message-1", conversationID: "conversation-1", createdAt: Date(timeIntervalSince1970: 100))
        let otherConversationMessage = makeMessage(id: "message-3", conversationID: "conversation-2", createdAt: Date(timeIntervalSince1970: 50))

        try await store.save(laterMessage)
        try await store.save(earlierMessage)
        try await store.save(otherConversationMessage)

        let messages = try await store.messages(conversationID: "conversation-1")
        XCTAssertEqual(messages.map(\.id), ["message-1", "message-2"])
    }

    private func makeMessage(
        id: String,
        conversationID: String = "conversation-1",
        createdAt: Date = Date(timeIntervalSince1970: 100),
        status: MessageStatus = .pending
    ) -> ChatMessage {
        ChatMessage(
            id: id,
            conversationID: conversationID,
            senderPublicKey: "sender-public-key",
            receiverPublicKey: "receiver-public-key",
            body: "Hello",
            createdAt: createdAt,
            status: status,
            direction: .outbound
        )
    }
}
