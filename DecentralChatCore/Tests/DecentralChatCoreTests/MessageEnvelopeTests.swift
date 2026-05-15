//
//  MessageEnvelopeTests.swift
//  DecentralChatCoreTests
//
//  Created by Joseph Lee on 5/16/26.
//

import DecentralChatCore
import Foundation
import XCTest

final class MessageEnvelopeTests: XCTestCase {
    func testMessageEnvelopeEncodesAndDecodesSuccessfully() throws {
        let envelope = MessageEnvelope(
            id: "message-envelope-1",
            version: 1,
            type: .chatMessage,
            senderPublicKey: "sender-public-key",
            receiverPublicKey: "receiver-public-key",
            conversationID: "conversation-id",
            ciphertext: "mock-ciphertext",
            createdAt: Date(timeIntervalSince1970: 1_800),
            expiresAt: Date(timeIntervalSince1970: 3_600),
            nonce: "mock-nonce",
            signature: "mock-signature"
        )

        let encoded = try JSONEncoder().encode(envelope)
        let decoded = try JSONDecoder().decode(MessageEnvelope.self, from: encoded)

        XCTAssertEqual(decoded, envelope)
    }
}
