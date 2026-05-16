import DecentralChatCore
import Foundation
import XCTest

final class MockCryptoServiceTests: XCTestCase {
    func testEncryptAndSignCreatesValidMessageEnvelope() throws {
        let service = MockCryptoService()
        let message = makeMessage(body: "Hello")

        let envelope = try service.encryptAndSign(message)

        XCTAssertEqual(envelope.id, message.id)
        XCTAssertEqual(envelope.version, 1)
        XCTAssertEqual(envelope.type, .text)
        XCTAssertEqual(envelope.senderPublicKey, message.senderPublicKey)
        XCTAssertEqual(envelope.receiverPublicKey, message.receiverPublicKey)
        XCTAssertEqual(envelope.conversationID, message.conversationID)
        XCTAssertEqual(envelope.ciphertext, "Hello".data(using: .utf8)?.base64EncodedString())
        XCTAssertEqual(envelope.createdAt, message.createdAt)
        XCTAssertNil(envelope.expiresAt)
        XCTAssertNil(envelope.nonce)
        XCTAssertEqual(envelope.signature, "mock-signature")
    }

    func testDecryptAndVerifyRestoresOriginalMessageBody() async throws {
        let service = MockCryptoService()
        let originalMessage = makeMessage(body: "Hello from mock crypto")
        let envelope = try service.encryptAndSign(originalMessage)

        let decryptedMessage = try await service.decryptAndVerify(envelope)

        XCTAssertEqual(decryptedMessage.id, originalMessage.id)
        XCTAssertEqual(decryptedMessage.conversationID, originalMessage.conversationID)
        XCTAssertEqual(decryptedMessage.senderPublicKey, originalMessage.senderPublicKey)
        XCTAssertEqual(decryptedMessage.receiverPublicKey, originalMessage.receiverPublicKey)
        XCTAssertEqual(decryptedMessage.body, originalMessage.body)
        XCTAssertEqual(decryptedMessage.createdAt, originalMessage.createdAt)
        XCTAssertEqual(decryptedMessage.status, .delivered)
        XCTAssertEqual(decryptedMessage.direction, .incoming)
    }

    func testDecryptAndVerifyThrowsUnsupportedEnvelopeVersion() async {
        let service = MockCryptoService()
        let envelope = makeEnvelope(version: 999, ciphertext: "Hello".data(using: .utf8)?.base64EncodedString() ?? "")

        do {
            _ = try await service.decryptAndVerify(envelope)
            XCTFail("Expected CryptoError.unsupportedEnvelopeVersion")
        } catch let error as CryptoError {
            XCTAssertEqual(error, .unsupportedEnvelopeVersion)
        } catch {
            XCTFail("Expected CryptoError.unsupportedEnvelopeVersion, got \(error)")
        }
    }

    func testDecryptAndVerifyThrowsDecryptFailedForInvalidBase64Ciphertext() async {
        let service = MockCryptoService()
        let envelope = makeEnvelope(version: 1, ciphertext: "not valid base64")

        do {
            _ = try await service.decryptAndVerify(envelope)
            XCTFail("Expected CryptoError.decryptFailed")
        } catch let error as CryptoError {
            XCTAssertEqual(error, .decryptFailed)
        } catch {
            XCTFail("Expected CryptoError.decryptFailed, got \(error)")
        }
    }

    func testMockCryptoServiceDoesNotImportForbiddenCryptoModule() throws {
        let testFileURL = URL(fileURLWithPath: #filePath)
        let packageRootURL = testFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let sourceURL = packageRootURL
            .appendingPathComponent("Sources")
            .appendingPathComponent("DecentralChatCore")
            .appendingPathComponent("Mocks")
            .appendingPathComponent("MockCryptoService.swift")
        let source = try String(contentsOf: sourceURL, encoding: .utf8)
        let forbiddenImport = "import " + "Crypto" + "Kit"

        XCTAssertFalse(source.contains(forbiddenImport))
    }

    private func makeMessage(body: String) -> ChatMessage {
        ChatMessage(
            id: "message-1",
            conversationID: "conversation-1",
            senderPublicKey: "sender-public-key",
            receiverPublicKey: "receiver-public-key",
            body: body,
            createdAt: Date(timeIntervalSince1970: 100),
            status: .pending,
            direction: .outbound
        )
    }

    private func makeEnvelope(version: Int, ciphertext: String) -> MessageEnvelope {
        MessageEnvelope(
            id: "message-1",
            version: version,
            type: .text,
            senderPublicKey: "sender-public-key",
            receiverPublicKey: "receiver-public-key",
            conversationID: "conversation-1",
            ciphertext: ciphertext,
            createdAt: Date(timeIntervalSince1970: 100),
            expiresAt: nil,
            nonce: nil,
            signature: "mock-signature"
        )
    }
}
