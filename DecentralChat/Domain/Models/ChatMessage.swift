//
//  ChatMessage.swift
//  DecentralChat
//
//  Created by Joseph Lee on 5/15/26.
//

import Foundation

struct ChatMessage: Codable, Equatable, Identifiable {
    let id: String
    let conversationID: String
    let senderPublicKey: String
    let receiverPublicKey: String
    let body: String
    let createdAt: Date
    let status: MessageStatus
    let direction: MessageDirection
}
