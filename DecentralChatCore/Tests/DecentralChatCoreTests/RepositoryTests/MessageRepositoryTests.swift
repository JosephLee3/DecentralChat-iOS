import DecentralChatCore
import Foundation
import XCTest

final class MessageRepositoryTests: XCTestCase {
    func testSendTextSuccessSavesOutgoingMessageAndUpdatesStatusToSent() async throws {
        let fixture = try await makeFixture()

        try await fixture.repository.sendText("Hello", to: fixture.contact)

        let messages = try await fixture.messageStore.messages(conversationID: fixture.conversationID)
        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages.first?.body, "Hello")
        XCTAssertEqual(messages.first?.senderPublicKey, fixture.identity.publicKey)
        XCTAssertEqual(messages.first?.receiverPublicKey, fixture.contact.publicKey)
        XCTAssertEqual(messages.first?.status, .sent)
        XCTAssertEqual(messages.first?.direction, .outgoing)
    }

    func testSendTextFailureUpdatesSavedMessageStatusToFailed() async throws {
        let fixture = try await makeFixture()
        fixture.transport.shouldFailSend = true

        do {
            try await fixture.repository.sendText("Hello", to: fixture.contact)
            XCTFail("Expected TransportError.sendFailed")
        } catch let error as TransportError {
            XCTAssertEqual(error, .sendFailed)
        }

        let messages = try await fixture.messageStore.messages(conversationID: fixture.conversationID)
        XCTAssertEqual(messages.first?.status, .failed)
    }

    func testSendTextFailureStillLeavesMessageInMessageStore() async throws {
        let fixture = try await makeFixture()
        fixture.transport.shouldFailSend = true

        do {
            try await fixture.repository.sendText("Hello", to: fixture.contact)
        } catch {
            // Expected failure for this test.
        }

        let messages = try await fixture.messageStore.messages(conversationID: fixture.conversationID)
        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages.first?.body, "Hello")
    }

    func testSendTextSendsOneEnvelopeThroughMockTransport() async throws {
        let fixture = try await makeFixture()

        try await fixture.repository.sendText("Hello", to: fixture.contact)

        XCTAssertEqual(fixture.transport.sentEnvelopes.count, 1)
        XCTAssertEqual(fixture.transport.sentEnvelopes.first?.conversationID, fixture.conversationID)
    }

    func testRetrySendFailedMessageSucceedsAndUpdatesStatusToSent() async throws {
        let fixture = try await makeFixture()
        let failedMessage = makeOutgoingMessage(
            id: "message-1",
            conversationID: fixture.conversationID,
            senderPublicKey: fixture.identity.publicKey,
            receiverPublicKey: fixture.contact.publicKey,
            status: .failed
        )
        try await fixture.messageStore.save(failedMessage)

        try await fixture.repository.retrySend(messageID: failedMessage.id)

        let retriedMessage = try await fixture.messageStore.message(id: failedMessage.id)
        XCTAssertEqual(retriedMessage?.id, failedMessage.id)
        XCTAssertEqual(retriedMessage?.body, failedMessage.body)
        XCTAssertEqual(retriedMessage?.createdAt, failedMessage.createdAt)
        XCTAssertEqual(retriedMessage?.status, .sent)
        XCTAssertEqual(fixture.transport.sentEnvelopes.count, 1)
        XCTAssertEqual(fixture.transport.sentEnvelopes.first?.id, failedMessage.id)
    }

    func testRetrySendFailureUpdatesStatusBackToFailedAndThrows() async throws {
        let fixture = try await makeFixture()
        let failedMessage = makeOutgoingMessage(
            id: "message-1",
            conversationID: fixture.conversationID,
            senderPublicKey: fixture.identity.publicKey,
            receiverPublicKey: fixture.contact.publicKey,
            status: .failed
        )
        try await fixture.messageStore.save(failedMessage)
        fixture.transport.shouldFailSend = true

        do {
            try await fixture.repository.retrySend(messageID: failedMessage.id)
            XCTFail("Expected TransportError.sendFailed")
        } catch let error as TransportError {
            XCTAssertEqual(error, .sendFailed)
        }

        let retriedMessage = try await fixture.messageStore.message(id: failedMessage.id)
        XCTAssertEqual(retriedMessage?.status, .failed)
    }

    func testRetrySendMissingMessageThrowsNotFound() async throws {
        let fixture = try await makeFixture()

        do {
            try await fixture.repository.retrySend(messageID: "missing-message")
            XCTFail("Expected StorageError.notFound")
        } catch StorageError.notFound {
            // Expected.
        } catch {
            XCTFail("Expected StorageError.notFound, got \(error)")
        }
    }

    func testRetrySendSentMessageIsRejectedAndStatusRemainsUnchanged() async throws {
        let fixture = try await makeFixture()
        let sentMessage = makeOutgoingMessage(
            id: "message-1",
            conversationID: fixture.conversationID,
            senderPublicKey: fixture.identity.publicKey,
            receiverPublicKey: fixture.contact.publicKey,
            status: .sent
        )
        try await fixture.messageStore.save(sentMessage)

        do {
            try await fixture.repository.retrySend(messageID: sentMessage.id)
            XCTFail("Expected StorageError.updateFailed")
        } catch StorageError.updateFailed {
            // Expected.
        } catch {
            XCTFail("Expected StorageError.updateFailed, got \(error)")
        }

        let loadedMessage = try await fixture.messageStore.message(id: sentMessage.id)
        XCTAssertEqual(loadedMessage?.status, .sent)
        XCTAssertTrue(fixture.transport.sentEnvelopes.isEmpty)
    }

    func testRetrySendSendingMessageIsRejectedAndStatusRemainsUnchanged() async throws {
        let fixture = try await makeFixture()
        let sendingMessage = makeOutgoingMessage(
            id: "message-1",
            conversationID: fixture.conversationID,
            senderPublicKey: fixture.identity.publicKey,
            receiverPublicKey: fixture.contact.publicKey,
            status: .sending
        )
        try await fixture.messageStore.save(sendingMessage)

        do {
            try await fixture.repository.retrySend(messageID: sendingMessage.id)
            XCTFail("Expected StorageError.updateFailed")
        } catch StorageError.updateFailed {
            // Expected.
        } catch {
            XCTFail("Expected StorageError.updateFailed, got \(error)")
        }

        let loadedMessage = try await fixture.messageStore.message(id: sendingMessage.id)
        XCTAssertEqual(loadedMessage?.status, .sending)
        XCTAssertTrue(fixture.transport.sentEnvelopes.isEmpty)
    }

    func testObserveIncomingMessagesSavesIncomingMessage() async throws {
        let fixture = try await makeFixture()
        let incomingMessage = makeIncomingMessage(id: "incoming-1", conversationID: fixture.conversationID)
        let envelope = try fixture.cryptoService.encryptAndSign(incomingMessage)
        var iterator = fixture.repository.observeIncomingMessages().makeAsyncIterator()

        fixture.transport.simulateIncoming(envelope)
        let observedMessage = await iterator.next()

        XCTAssertEqual(observedMessage?.id, incomingMessage.id)
        XCTAssertEqual(observedMessage?.body, incomingMessage.body)
        let savedMessage = try await fixture.messageStore.message(id: incomingMessage.id)
        XCTAssertEqual(savedMessage?.body, incomingMessage.body)
    }

    func testObserveIncomingMessagesIgnoresDuplicateMessageIDs() async throws {
        let fixture = try await makeFixture()
        let incomingMessage = makeIncomingMessage(id: "incoming-1", conversationID: fixture.conversationID)
        let envelope = try fixture.cryptoService.encryptAndSign(incomingMessage)
        var iterator = fixture.repository.observeIncomingMessages().makeAsyncIterator()

        fixture.transport.simulateIncoming(envelope)
        let firstObservedMessage = await iterator.next()
        fixture.transport.simulateIncoming(envelope)

        XCTAssertEqual(firstObservedMessage?.id, incomingMessage.id)
        let savedMessages = try await fixture.messageStore.messages(conversationID: fixture.conversationID)
        XCTAssertEqual(savedMessages.filter { $0.id == incomingMessage.id }.count, 1)
    }

    func testObserveIncomingMessagesIgnoresUnsupportedEnvelopeVersion() async throws {
        let fixture = try await makeFixture()
        let unsupportedEnvelope = makeEnvelope(id: "incoming-unsupported", version: 999, ciphertext: "SGVsbG8=")
        let validEnvelope = try fixture.cryptoService.encryptAndSign(
            makeIncomingMessage(id: "incoming-valid", conversationID: fixture.conversationID)
        )
        var iterator = fixture.repository.observeIncomingMessages().makeAsyncIterator()

        fixture.transport.simulateIncoming(unsupportedEnvelope)
        fixture.transport.simulateIncoming(validEnvelope)
        let observedMessage = await iterator.next()

        XCTAssertEqual(observedMessage?.id, "incoming-valid")
        let unsupportedMessage = try await fixture.messageStore.message(id: "incoming-unsupported")
        XCTAssertNil(unsupportedMessage)
    }

    func testObserveIncomingMessagesContinuesAfterBadEnvelopeAndProcessesLaterValidEnvelope() async throws {
        let fixture = try await makeFixture()
        let badEnvelope = makeEnvelope(id: "incoming-bad", version: 1, ciphertext: "not valid base64")
        let validMessage = makeIncomingMessage(id: "incoming-valid", conversationID: fixture.conversationID)
        let validEnvelope = try fixture.cryptoService.encryptAndSign(validMessage)
        var iterator = fixture.repository.observeIncomingMessages().makeAsyncIterator()

        fixture.transport.simulateIncoming(badEnvelope)
        fixture.transport.simulateIncoming(validEnvelope)
        let observedMessage = await iterator.next()

        XCTAssertEqual(observedMessage?.id, validMessage.id)
        XCTAssertEqual(observedMessage?.body, validMessage.body)
        let badMessage = try await fixture.messageStore.message(id: badEnvelope.id)
        XCTAssertNil(badMessage)
    }

    private func makeFixture() async throws -> RepositoryFixture {
        let identity = UserIdentity(
            id: "identity-1",
            displayName: "Alice",
            publicKey: "alice-public-key",
            createdAt: Date(timeIntervalSince1970: 100)
        )
        let contact = Contact(
            id: "contact-1",
            displayName: "Bob",
            publicKey: "bob-public-key",
            createdAt: Date(timeIntervalSince1970: 200)
        )
        let messageStore = InMemoryMessageStore()
        let identityStore = InMemoryIdentityStore()
        let cryptoService = MockCryptoService()
        let transport = MockTransport()
        let repository = MessageRepository(
            messageStore: messageStore,
            identityStore: identityStore,
            cryptoService: cryptoService,
            transport: transport
        )

        try await identityStore.saveIdentity(identity, privateKeyData: Data([1, 2, 3]))

        return RepositoryFixture(
            identity: identity,
            contact: contact,
            conversationID: ConversationIDFactory.makeConversationID(
                publicKeyA: identity.publicKey,
                publicKeyB: contact.publicKey
            ),
            messageStore: messageStore,
            identityStore: identityStore,
            cryptoService: cryptoService,
            transport: transport,
            repository: repository
        )
    }

    private func makeIncomingMessage(id: String, conversationID: String) -> ChatMessage {
        ChatMessage(
            id: id,
            conversationID: conversationID,
            senderPublicKey: "bob-public-key",
            receiverPublicKey: "alice-public-key",
            body: "Incoming body",
            createdAt: Date(timeIntervalSince1970: 300),
            status: .sent,
            direction: .outgoing
        )
    }

    private func makeOutgoingMessage(
        id: String,
        conversationID: String,
        senderPublicKey: String,
        receiverPublicKey: String,
        status: MessageStatus
    ) -> ChatMessage {
        ChatMessage(
            id: id,
            conversationID: conversationID,
            senderPublicKey: senderPublicKey,
            receiverPublicKey: receiverPublicKey,
            body: "Retry body",
            createdAt: Date(timeIntervalSince1970: 400),
            status: status,
            direction: .outgoing
        )
    }

    private func makeEnvelope(id: String, version: Int, ciphertext: String) -> MessageEnvelope {
        MessageEnvelope(
            id: id,
            version: version,
            type: .text,
            senderPublicKey: "bob-public-key",
            receiverPublicKey: "alice-public-key",
            conversationID: ConversationIDFactory.makeConversationID(
                publicKeyA: "alice-public-key",
                publicKeyB: "bob-public-key"
            ),
            ciphertext: ciphertext,
            createdAt: Date(timeIntervalSince1970: 300),
            expiresAt: nil,
            nonce: nil,
            signature: "mock-signature"
        )
    }
}

private struct RepositoryFixture {
    let identity: UserIdentity
    let contact: Contact
    let conversationID: String
    let messageStore: InMemoryMessageStore
    let identityStore: InMemoryIdentityStore
    let cryptoService: MockCryptoService
    let transport: MockTransport
    let repository: MessageRepository
}
