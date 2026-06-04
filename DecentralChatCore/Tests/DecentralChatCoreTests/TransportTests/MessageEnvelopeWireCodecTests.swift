import DecentralChatCore
import Foundation
import XCTest

final class MessageEnvelopeWireCodecTests: XCTestCase {
    private let codec = MessageEnvelopeWireCodec()

    func testEncodeDecodeRoundTripPreservesMessageEnvelope() throws {
        let envelope = makeEnvelope(expiresAt: Date(timeIntervalSince1970: 3_600), nonce: "mock-nonce")

        let data = try codec.encode(envelope)
        let decoded = try codec.decode(data)

        XCTAssertEqual(decoded, envelope)
    }

    func testEncodedJSONUsesStableISO8601DateEncoding() throws {
        let envelope = makeEnvelope(createdAt: Date(timeIntervalSince1970: 100))

        let data = try codec.encode(envelope)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(object["createdAt"] as? String, "1970-01-01T00:01:40Z")
    }

    func testExpiresAtNilRoundTrips() throws {
        let envelope = makeEnvelope(expiresAt: nil)

        let decoded = try codec.decode(try codec.encode(envelope))

        XCTAssertNil(decoded.expiresAt)
        XCTAssertEqual(decoded, envelope)
    }

    func testExpiresAtNonNilRoundTrips() throws {
        let expiresAt = Date(timeIntervalSince1970: 3_600)
        let envelope = makeEnvelope(expiresAt: expiresAt)

        let decoded = try codec.decode(try codec.encode(envelope))

        XCTAssertEqual(decoded.expiresAt, expiresAt)
        XCTAssertEqual(decoded, envelope)
    }

    func testNonceNilRoundTrips() throws {
        let envelope = makeEnvelope(nonce: nil)

        let decoded = try codec.decode(try codec.encode(envelope))

        XCTAssertNil(decoded.nonce)
        XCTAssertEqual(decoded, envelope)
    }

    func testNonceNonNilRoundTrips() throws {
        let envelope = makeEnvelope(nonce: "mock-nonce")

        let decoded = try codec.decode(try codec.encode(envelope))

        XCTAssertEqual(decoded.nonce, "mock-nonce")
        XCTAssertEqual(decoded, envelope)
    }

    func testMalformedJSONThrows() {
        let data = Data("{ not valid json".utf8)

        XCTAssertThrowsError(try codec.decode(data))
    }

    func testMissingRequiredFieldThrows() throws {
        let data = Data("""
        {
          "version": 1,
          "type": "chatMessage",
          "senderPublicKey": "sender-public-key",
          "receiverPublicKey": "receiver-public-key",
          "conversationID": "conversation-1",
          "ciphertext": "mock-ciphertext",
          "createdAt": "1970-01-01T00:01:40Z",
          "signature": "mock-signature"
        }
        """.utf8)

        XCTAssertThrowsError(try codec.decode(data))
    }

    func testInvalidTypeEnumValueThrows() throws {
        let data = Data("""
        {
          "id": "envelope-1",
          "version": 1,
          "type": "unsupported-type",
          "senderPublicKey": "sender-public-key",
          "receiverPublicKey": "receiver-public-key",
          "conversationID": "conversation-1",
          "ciphertext": "mock-ciphertext",
          "createdAt": "1970-01-01T00:01:40Z",
          "signature": "mock-signature"
        }
        """.utf8)

        XCTAssertThrowsError(try codec.decode(data))
    }

    func testUnsupportedVersionDecodesBecauseRepositoryValidatesEnvelopeVersion() throws {
        let envelope = makeEnvelope(version: 999)

        let decoded = try codec.decode(try codec.encode(envelope))

        XCTAssertEqual(decoded.version, 999)
    }

    func testRepositoryShapedEnvelopeCanRoundTripAndSendThroughMockTransport() async throws {
        let message = makeOutgoingChatMessage()
        let envelope = try MockCryptoService().encryptAndSign(message)
        let decoded = try codec.decode(try codec.encode(envelope))
        let transport = MockTransport()

        try await transport.send(decoded)

        XCTAssertEqual(transport.sentEnvelopes, [envelope])
    }

    func testDecodedIncomingEnvelopeCanBeObservedThroughMockTransport() async throws {
        let envelope = makeEnvelope(id: "incoming-envelope")
        let decoded = try codec.decode(try codec.encode(envelope))
        let transport = MockTransport()
        let stream = transport.observeIncomingMessages()
        var iterator = stream.makeAsyncIterator()

        transport.simulateIncoming(decoded)
        let receivedEnvelope = await iterator.next()

        XCTAssertEqual(receivedEnvelope, envelope)
    }

    func testUnsupportedVersionRemainsOwnedByMessageRepository() async throws {
        let fixture = try await makeRepositoryFixture()
        let unsupportedEnvelope = makeEnvelope(
            id: "unsupported-envelope",
            version: 999,
            ciphertext: "SGVsbG8="
        )
        let decodedUnsupportedEnvelope = try codec.decode(try codec.encode(unsupportedEnvelope))
        let validMessage = makeIncomingChatMessage(id: "valid-message")
        let validEnvelope = try fixture.cryptoService.encryptAndSign(validMessage)
        var iterator = fixture.repository.observeIncomingMessages().makeAsyncIterator()

        fixture.transport.simulateIncoming(decodedUnsupportedEnvelope)
        fixture.transport.simulateIncoming(validEnvelope)
        let observedMessage = await iterator.next()

        XCTAssertEqual(observedMessage?.id, validMessage.id)
        let unsupportedMessage = try await fixture.messageStore.message(id: unsupportedEnvelope.id)
        XCTAssertNil(unsupportedMessage)
    }

    private func makeEnvelope(
        id: String = "envelope-1",
        version: Int = 1,
        createdAt: Date = Date(timeIntervalSince1970: 100),
        expiresAt: Date? = nil,
        nonce: String? = nil
    ) -> MessageEnvelope {
        MessageEnvelope(
            id: id,
            version: version,
            type: .chatMessage,
            senderPublicKey: "sender-public-key",
            receiverPublicKey: "receiver-public-key",
            conversationID: "conversation-1",
            ciphertext: "mock-ciphertext",
            createdAt: createdAt,
            expiresAt: expiresAt,
            nonce: nonce,
            signature: "mock-signature"
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

    private func makeOutgoingChatMessage() -> ChatMessage {
        ChatMessage(
            id: "outgoing-message",
            conversationID: ConversationIDFactory.makeConversationID(
                publicKeyA: "alice-public-key",
                publicKeyB: "bob-public-key"
            ),
            senderPublicKey: "alice-public-key",
            receiverPublicKey: "bob-public-key",
            body: "Hello",
            createdAt: Date(timeIntervalSince1970: 200),
            status: .sending,
            direction: .outgoing
        )
    }

    private func makeIncomingChatMessage(id: String) -> ChatMessage {
        ChatMessage(
            id: id,
            conversationID: ConversationIDFactory.makeConversationID(
                publicKeyA: "alice-public-key",
                publicKeyB: "bob-public-key"
            ),
            senderPublicKey: "bob-public-key",
            receiverPublicKey: "alice-public-key",
            body: "Incoming body",
            createdAt: Date(timeIntervalSince1970: 400),
            status: .sent,
            direction: .outgoing
        )
    }

    private func makeRepositoryFixture() async throws -> RepositoryFixture {
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
        let identity = UserIdentity(
            id: "identity-1",
            displayName: "Alice",
            publicKey: "alice-public-key",
            createdAt: Date(timeIntervalSince1970: 100)
        )

        try await identityStore.saveIdentity(identity, privateKeyData: Data([1, 2, 3]))

        return RepositoryFixture(
            messageStore: messageStore,
            cryptoService: cryptoService,
            transport: transport,
            repository: repository
        )
    }
}

private struct RepositoryFixture {
    let messageStore: InMemoryMessageStore
    let cryptoService: MockCryptoService
    let transport: MockTransport
    let repository: MessageRepository
}
