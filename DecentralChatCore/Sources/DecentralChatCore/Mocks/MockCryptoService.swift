import Foundation

// MockCryptoService is NOT real encryption. It only Base64-encodes message bodies for tests and MVP flow verification.
public struct MockCryptoService: CryptoService {
    public init() {}

    public func encryptAndSign(_ message: ChatMessage) throws -> MessageEnvelope {
        let ciphertext = Data(message.body.utf8).base64EncodedString()

        return MessageEnvelope(
            id: message.id,
            version: 1,
            type: .text,
            senderPublicKey: message.senderPublicKey,
            receiverPublicKey: message.receiverPublicKey,
            conversationID: message.conversationID,
            ciphertext: ciphertext,
            createdAt: message.createdAt,
            expiresAt: nil,
            nonce: nil,
            signature: "mock-signature"
        )
    }

    public func decryptAndVerify(_ envelope: MessageEnvelope) async throws -> ChatMessage {
        guard envelope.version == 1 else {
            throw CryptoError.unsupportedEnvelopeVersion
        }

        guard let data = Data(base64Encoded: envelope.ciphertext),
              let body = String(data: data, encoding: .utf8) else {
            throw CryptoError.decryptFailed
        }

        return ChatMessage(
            id: envelope.id,
            conversationID: envelope.conversationID,
            senderPublicKey: envelope.senderPublicKey,
            receiverPublicKey: envelope.receiverPublicKey,
            body: body,
            createdAt: envelope.createdAt,
            status: .delivered,
            direction: .incoming
        )
    }
}
