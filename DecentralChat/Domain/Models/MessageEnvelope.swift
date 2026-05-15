//
//  MessageEnvelope.swift
//  DecentralChat
//
//  Created by Joseph Lee on 5/15/26.
//

import Foundation

struct MessageEnvelope: Codable, Equatable, Identifiable {
    let id: String
    let version: Int
    let type: MessageEnvelopeType
    let senderPublicKey: String
    let receiverPublicKey: String
    let conversationID: String
    let ciphertext: String
    let createdAt: Date
    let expiresAt: Date?
    let nonce: String
    let signature: String
}
