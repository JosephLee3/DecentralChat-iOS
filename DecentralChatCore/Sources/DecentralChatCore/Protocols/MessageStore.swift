import Foundation

public protocol MessageStore {
    func save(_ message: ChatMessage) async throws
    func updateStatus(_ messageID: String, _ status: MessageStatus) async throws
    func message(id: String) async throws -> ChatMessage?
    func exists(messageID: String) async throws -> Bool
    func messages(conversationID: String) async throws -> [ChatMessage]
    func recentConversations() async throws -> [Conversation]
}
