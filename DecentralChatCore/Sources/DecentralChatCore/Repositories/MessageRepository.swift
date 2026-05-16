import Foundation

public final class MessageRepository {
    private let messageStore: MessageStore
    private let identityStore: IdentityStore
    private let cryptoService: CryptoService
    private let transport: ChatTransport

    public init(
        messageStore: MessageStore,
        identityStore: IdentityStore,
        cryptoService: CryptoService,
        transport: ChatTransport
    ) {
        self.messageStore = messageStore
        self.identityStore = identityStore
        self.cryptoService = cryptoService
        self.transport = transport
    }

    public func sendText(_ text: String, to contact: Contact) async throws {
        let identity = try await identityStore.loadIdentity()
        let conversationID = ConversationIDFactory.makeConversationID(
            publicKeyA: identity.publicKey,
            publicKeyB: contact.publicKey
        )
        let message = ChatMessage(
            id: UUID().uuidString,
            conversationID: conversationID,
            senderPublicKey: identity.publicKey,
            receiverPublicKey: contact.publicKey,
            body: text,
            createdAt: Date(),
            status: .sending,
            direction: .outgoing
        )

        try await messageStore.save(message)

        do {
            let envelope = try cryptoService.encryptAndSign(message)
            try await transport.send(envelope)
            try await messageStore.updateStatus(message.id, .sent)
        } catch {
            try? await messageStore.updateStatus(message.id, .failed)
            throw error
        }
    }

    public func observeIncomingMessages() -> AsyncStream<ChatMessage> {
        let envelopes = transport.observeIncomingMessages()

        return AsyncStream { continuation in
            let task = Task {
                for await envelope in envelopes {
                    do {
                        guard envelope.version == 1 else {
                            continue
                        }

                        let exists = try await messageStore.exists(messageID: envelope.id)
                        guard !exists else {
                            continue
                        }

                        let message = try await cryptoService.decryptAndVerify(envelope)
                        try await messageStore.save(message)
                        continuation.yield(message)
                    } catch {
                        continue
                    }
                }

                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}
