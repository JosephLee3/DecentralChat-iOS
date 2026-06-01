import DecentralChatCore
import Foundation
import XCTest

final class JSONMessageStoreTests: XCTestCase {
    func testSaveMessagePersistsAcrossStoreRecreation() async throws {
        let fileURL = makeTemporaryFileURL()
        let message = makeMessage(id: "message-1")
        let store = JSONMessageStore(fileURL: fileURL)

        try await store.save(message)

        let recreatedStore = JSONMessageStore(fileURL: fileURL)
        let loadedMessage = try await recreatedStore.message(id: message.id)
        XCTAssertEqual(loadedMessage, message)
    }

    func testUpdateStatusPersistsAcrossStoreRecreation() async throws {
        let fileURL = makeTemporaryFileURL()
        let message = makeMessage(id: "message-1", status: .pending)
        let store = JSONMessageStore(fileURL: fileURL)

        try await store.save(message)
        try await store.updateStatus(message.id, .sent)

        let recreatedStore = JSONMessageStore(fileURL: fileURL)
        let loadedMessage = try await recreatedStore.message(id: message.id)
        XCTAssertEqual(loadedMessage?.status, .sent)
    }

    func testMessagesForConversationAreSortedByCreatedAt() async throws {
        let fileURL = makeTemporaryFileURL()
        let store = JSONMessageStore(fileURL: fileURL)
        let laterMessage = makeMessage(id: "message-2", conversationID: "conversation-1", createdAt: Date(timeIntervalSince1970: 200))
        let earlierMessage = makeMessage(id: "message-1", conversationID: "conversation-1", createdAt: Date(timeIntervalSince1970: 100))
        let otherConversationMessage = makeMessage(id: "message-3", conversationID: "conversation-2", createdAt: Date(timeIntervalSince1970: 50))

        try await store.save(laterMessage)
        try await store.save(earlierMessage)
        try await store.save(otherConversationMessage)

        let recreatedStore = JSONMessageStore(fileURL: fileURL)
        let messages = try await recreatedStore.messages(conversationID: "conversation-1")
        XCTAssertEqual(messages.map(\.id), ["message-1", "message-2"])
    }

    func testRecentConversationsAreSortedByLatestMessageTime() async throws {
        let fileURL = makeTemporaryFileURL()
        let store = JSONMessageStore(fileURL: fileURL)
        let olderConversationMessage = makeMessage(
            id: "message-1",
            conversationID: "conversation-1",
            createdAt: Date(timeIntervalSince1970: 100)
        )
        let newerConversationFirstMessage = makeMessage(
            id: "message-2",
            conversationID: "conversation-2",
            createdAt: Date(timeIntervalSince1970: 50)
        )
        let newerConversationLatestMessage = makeMessage(
            id: "message-3",
            conversationID: "conversation-2",
            createdAt: Date(timeIntervalSince1970: 300)
        )

        try await store.save(olderConversationMessage)
        try await store.save(newerConversationFirstMessage)
        try await store.save(newerConversationLatestMessage)

        let recreatedStore = JSONMessageStore(fileURL: fileURL)
        let conversations = try await recreatedStore.recentConversations()
        XCTAssertEqual(conversations.map(\.id), ["conversation-2", "conversation-1"])
        XCTAssertEqual(conversations.first?.updatedAt, Date(timeIntervalSince1970: 300))
    }

    func testMessagesFromDifferentConversationsDoNotMix() async throws {
        let fileURL = makeTemporaryFileURL()
        let store = JSONMessageStore(fileURL: fileURL)
        let conversationOneMessage = makeMessage(id: "message-1", conversationID: "conversation-1")
        let conversationTwoMessage = makeMessage(id: "message-2", conversationID: "conversation-2")

        try await store.save(conversationOneMessage)
        try await store.save(conversationTwoMessage)

        let recreatedStore = JSONMessageStore(fileURL: fileURL)
        let messages = try await recreatedStore.messages(conversationID: "conversation-1")
        XCTAssertEqual(messages, [conversationOneMessage])
    }

    func testDateFieldsSurviveReload() async throws {
        let fileURL = makeTemporaryFileURL()
        let createdAt = Date(timeIntervalSince1970: 100)
        let message = makeMessage(id: "message-1", createdAt: createdAt)
        let store = JSONMessageStore(fileURL: fileURL)

        try await store.save(message)

        let recreatedStore = JSONMessageStore(fileURL: fileURL)
        let loadedMessage = try await recreatedStore.message(id: message.id)
        XCTAssertEqual(loadedMessage?.createdAt, createdAt)
    }

    func testUpdateStatusForMissingMessageThrowsNotFound() async throws {
        let fileURL = makeTemporaryFileURL()
        let store = JSONMessageStore(fileURL: fileURL)

        do {
            try await store.updateStatus("missing-message", .sent)
            XCTFail("Expected StorageError.notFound")
        } catch StorageError.notFound {
            // Expected.
        } catch {
            XCTFail("Expected StorageError.notFound, got \(error)")
        }
    }

    func testExistsReturnsTrueAfterSaving() async throws {
        let fileURL = makeTemporaryFileURL()
        let store = JSONMessageStore(fileURL: fileURL)
        let message = makeMessage(id: "message-1")

        try await store.save(message)

        let recreatedStore = JSONMessageStore(fileURL: fileURL)
        let exists = try await recreatedStore.exists(messageID: message.id)
        XCTAssertTrue(exists)
    }

    private func makeTemporaryFileURL() -> URL {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)

        addTeardownBlock {
            try? FileManager.default.removeItem(at: directoryURL)
        }

        return directoryURL.appendingPathComponent("messages.json")
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
