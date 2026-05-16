import Foundation

public protocol CryptoService {
    func encryptAndSign(_ message: ChatMessage) throws -> MessageEnvelope
    func decryptAndVerify(_ envelope: MessageEnvelope) async throws -> ChatMessage
}
