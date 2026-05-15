//
//  ChatMessage.swift
//  DecentralChatCore
//
//  Created by Joseph Lee on 5/16/26.
//

import Foundation

public struct ChatMessage: Codable, Equatable, Identifiable {
    public let id: String
    public let conversationID: String
    public let senderPublicKey: String
    public let receiverPublicKey: String
    public let body: String
    public let createdAt: Date
    public let status: MessageStatus
    public let direction: MessageDirection

    public init(
        id: String,
        conversationID: String,
        senderPublicKey: String,
        receiverPublicKey: String,
        body: String,
        createdAt: Date,
        status: MessageStatus,
        direction: MessageDirection
    ) {
        self.id = id
        self.conversationID = conversationID
        self.senderPublicKey = senderPublicKey
        self.receiverPublicKey = receiverPublicKey
        self.body = body
        self.createdAt = createdAt
        self.status = status
        self.direction = direction
    }
}
