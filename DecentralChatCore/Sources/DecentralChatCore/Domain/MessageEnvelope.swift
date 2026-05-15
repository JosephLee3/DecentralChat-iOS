//
//  MessageEnvelope.swift
//  DecentralChatCore
//
//  Created by Joseph Lee on 5/16/26.
//

import Foundation

public struct MessageEnvelope: Codable, Equatable, Identifiable {
    public let id: String
    public let version: Int
    public let type: MessageEnvelopeType
    public let senderPublicKey: String
    public let receiverPublicKey: String
    public let conversationID: String
    public let ciphertext: String
    public let createdAt: Date
    public let expiresAt: Date?
    public let nonce: String
    public let signature: String

    public init(
        id: String,
        version: Int,
        type: MessageEnvelopeType,
        senderPublicKey: String,
        receiverPublicKey: String,
        conversationID: String,
        ciphertext: String,
        createdAt: Date,
        expiresAt: Date?,
        nonce: String,
        signature: String
    ) {
        self.id = id
        self.version = version
        self.type = type
        self.senderPublicKey = senderPublicKey
        self.receiverPublicKey = receiverPublicKey
        self.conversationID = conversationID
        self.ciphertext = ciphertext
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.nonce = nonce
        self.signature = signature
    }
}
