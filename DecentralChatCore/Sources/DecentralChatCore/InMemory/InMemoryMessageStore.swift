import Foundation

public actor InMemoryMessageStore: MessageStore {
    private var messagesByID: [String: ChatMessage]

    public init(messages: [ChatMessage] = []) {
        self.messagesByID = Dictionary(uniqueKeysWithValues: messages.map { ($0.id, $0) })
    }

    public func save(_ message: ChatMessage) async throws {
        messagesByID[message.id] = message
    }

    public func updateStatus(_ messageID: String, _ status: MessageStatus) async throws {
        guard let existingMessage = messagesByID[messageID] else {
            throw StorageError.notFound
        }

        messagesByID[messageID] = ChatMessage(
            id: existingMessage.id,
            conversationID: existingMessage.conversationID,
            senderPublicKey: existingMessage.senderPublicKey,
            receiverPublicKey: existingMessage.receiverPublicKey,
            body: existingMessage.body,
            createdAt: existingMessage.createdAt,
            status: status,
            direction: existingMessage.direction
        )
    }

    public func message(id: String) async throws -> ChatMessage? {
        messagesByID[id]
    }

    public func exists(messageID: String) async throws -> Bool {
        messagesByID[messageID] != nil
    }

    public func messages(conversationID: String) async throws -> [ChatMessage] {
        messagesByID.values
            .filter { $0.conversationID == conversationID }
            .sorted { $0.createdAt < $1.createdAt }
    }

    public func recentConversations() async throws -> [Conversation] {
        let groupedMessages = Dictionary(grouping: messagesByID.values, by: \.conversationID)

        return groupedMessages.values
            .compactMap { messages in
                guard let firstMessage = messages.min(by: { $0.createdAt < $1.createdAt }),
                      let lastMessage = messages.max(by: { $0.createdAt < $1.createdAt }) else {
                    return nil
                }

                let participantPublicKeys = Set(messages.flatMap { [$0.senderPublicKey, $0.receiverPublicKey] })

                return Conversation(
                    id: firstMessage.conversationID,
                    participantPublicKeys: participantPublicKeys.sorted(),
                    createdAt: firstMessage.createdAt,
                    updatedAt: lastMessage.createdAt
                )
            }
            .sorted { $0.updatedAt > $1.updatedAt }
    }
}
